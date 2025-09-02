package com.nicevideo.auth.service.impl;

import com.nicevideo.auth.dto.AuthResponse;
import com.nicevideo.auth.dto.LoginRequest;
import com.nicevideo.auth.dto.RegisterRequest;
import com.nicevideo.auth.dto.UserDto;
import com.nicevideo.auth.feign.UserFeignClient;
import com.nicevideo.auth.service.AuthService;
import com.nicevideo.auth.util.JsonUtils;
import com.nicevideo.common.constant.ErrorMessages;
import com.nicevideo.common.exception.BusinessException;
import com.nicevideo.common.result.Result;
import com.nicevideo.common.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 认证服务实现类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    
    private final UserFeignClient userFeignClient;
    private final JwtUtils jwtUtils;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    @Override
    public AuthResponse login(LoginRequest request) {
        // 查询用户
        Result<Object> result = userFeignClient.getByUsername(request.getUsername());
        if (result.getCode() != 200 || result.getData() == null) {
            throw new BusinessException(ErrorMessages.USER_USERNAME_OR_PASSWORD_ERROR);
        }
        
        // 将Object转换为UserDto
        UserDto user = JsonUtils.convertToUserDto(result.getData());
        if (user == null) {
            throw new BusinessException(ErrorMessages.USER_USERNAME_OR_PASSWORD_ERROR);
        }
        
        // 验证密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BusinessException(ErrorMessages.USER_USERNAME_OR_PASSWORD_ERROR);
        }
        
        // 检查用户状态
        if (user.getStatus() == 0) {
            throw new BusinessException("用户已被禁用");
        }
        
        // 生成Token
        String accessToken = jwtUtils.generateToken(user.getUsername(), user.getId());
        String refreshToken = jwtUtils.generateToken(user.getUsername() + "_refresh", user.getId());
        
        return new AuthResponse(accessToken, refreshToken, user.getUsername(), user.getId());
    }
    
    @Override
    public AuthResponse register(RegisterRequest request) {
        try {
            // 检查用户名是否已存在
            Result<Object> existingUser = userFeignClient.getByUsername(request.getUsername());
            log.info("检查用户名是否存在，响应: code={}, message={}, data={}", 
                    existingUser.getCode(), existingUser.getMessage(), existingUser.getData());
            if (existingUser.getCode() == 200 && existingUser.getData() != null) {
                throw new BusinessException("用户名已存在");
            }
            // 检查邮箱是否已存在
            Result<Object> existingEmail = userFeignClient.getByEmail(request.getEmail());
            log.info("检查邮箱是否存在，响应: code={}, message={}, data={}", 
                    existingEmail.getCode(), existingEmail.getMessage(), existingEmail.getData());
            if (existingEmail.getCode() == 200 && existingEmail.getData() != null) {
                throw new BusinessException("邮箱已存在");
            }
            // 检查手机号是否已存在
            Result<Object> existingPhone = userFeignClient.getByPhone(request.getPhone());
            log.info("检查手机号是否存在，响应: code={}, message={}, data={}", 
                    existingPhone.getCode(), existingPhone.getMessage(), existingPhone.getData());
            if (existingPhone.getCode() == 200 && existingPhone.getData() != null) {
                throw new BusinessException("手机号已存在");
            }
        } catch (BusinessException e) {
            log.error("检查用户名时发生异常: {} (错误码: {})", e.getMessage(), e.getCode());
            // 如果不是"用户不存在"的错误，重新抛出
            if (!"用户不存在".equals(e.getMessage()) && !"User not found".equals(e.getMessage()) && e.getCode() != 404) {
                // 保持原始错误码和错误信息
                throw e;
            }
            // 用户不存在是正常情况，继续注册流程
            log.info("用户不存在，继续注册流程");
        }
        
        try {
            // 创建用户
            UserDto user = new UserDto();
            user.setUsername(request.getUsername());
            user.setPassword(request.getPassword()); // 用户服务会处理密码加密
            user.setEmail(request.getEmail());
            user.setPhone(request.getPhone());
            user.setNickname(request.getNickname());
            user.setStatus(1);
            
            log.info("尝试创建用户: {}", user.getUsername());
            Result<Object> createResult = userFeignClient.createUser(user);
            log.info("创建用户响应: code={}, message={}, data={}", 
                    createResult.getCode(), createResult.getMessage(), createResult.getData());
            
            if (createResult.getCode() != 200) {
                throw new BusinessException("注册失败：" + createResult.getMessage());
            }

            // 由于返回类型是Object，我们需要转换
            Object userData = createResult.getData();
            if (userData == null) {
                throw new BusinessException("注册成功但获取用户信息失败");
            }
            
            // 将创建返回的数据转换为UserDto
            UserDto createdUser = JsonUtils.convertToUserDto(userData);
            if (createdUser == null) {
                // 如果转换失败，使用请求中的数据构建
                createdUser = new UserDto();
                createdUser.setId(1L); // 临时ID
                createdUser.setUsername(user.getUsername());
                createdUser.setEmail(user.getEmail());
            }
            
            // 生成Token
            String accessToken = jwtUtils.generateToken(createdUser.getUsername(), createdUser.getId());
            String refreshToken = jwtUtils.generateToken(createdUser.getUsername() + "_refresh", createdUser.getId());
            
            return new AuthResponse(accessToken, refreshToken, createdUser.getUsername(), createdUser.getId());
        } catch (BusinessException e) {
            // 重新抛出业务异常，保持原始错误信息和错误码
            log.error("用户注册失败: {} (错误码: {})", e.getMessage(), e.getCode());
            throw e;
        } catch (Exception e) {
            log.error("注册过程中发生未知错误", e);
            throw new BusinessException("注册失败，请稍后重试");
        }
    }
    
    @Override
    public AuthResponse refreshToken(String refreshToken) {
        // 验证refresh token
        if (!jwtUtils.validateToken(refreshToken)) {
            throw new BusinessException("刷新Token已过期或无效");
        }
        
        String username = jwtUtils.getUsernameFromToken(refreshToken);
        Long userId = jwtUtils.getUserIdFromToken(refreshToken);
        
        // 生成新的token
        String newAccessToken = jwtUtils.generateToken(username, userId);
        String newRefreshToken = jwtUtils.generateToken(username + "_refresh", userId);
        
        return new AuthResponse(newAccessToken, newRefreshToken, username, userId);
    }
    
    @Override
    public Boolean validateToken(String token) {
        return jwtUtils.validateToken(token);
    }
}
