package com.nicevideo.auth.service.impl;

import com.nicevideo.auth.dto.AuthResponse;
import com.nicevideo.auth.dto.LoginRequest;
import com.nicevideo.auth.dto.RegisterRequest;
import com.nicevideo.auth.dto.UserDto;
import com.nicevideo.auth.feign.UserFeignClient;
import com.nicevideo.auth.service.AuthService;
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
        Result<UserDto> result = userFeignClient.getByUsername(request.getUsername());
        if (result.getCode() != 200 || result.getData() == null) {
            throw new BusinessException(ErrorMessages.USER_USERNAME_OR_PASSWORD_ERROR);
        }
        
        UserDto user = result.getData();
        
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
        // 检查用户名是否已存在
        Result<UserDto> existingUser = userFeignClient.getByUsername(request.getUsername());
        if (existingUser.getCode() == 200 && existingUser.getData() != null) {
            throw new BusinessException("用户名已存在");
        }
        
        // 创建用户
        UserDto user = new UserDto();
        user.setUsername(request.getUsername());
        user.setPassword(request.getPassword()); // 用户服务会处理密码加密
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());
        user.setNickname(request.getNickname());
        user.setStatus(1);
        
        Result<UserDto> createResult = userFeignClient.createUser(user);
        if (createResult.getCode() != 200) {
            throw new BusinessException("注册失败：" + createResult.getMessage());
        }
        
        // 直接使用创建返回的用户信息
        UserDto createdUser = createResult.getData();
        if (createdUser == null) {
            throw new BusinessException("注册成功但获取用户信息失败");
        }
        
        // 生成Token
        String accessToken = jwtUtils.generateToken(createdUser.getUsername(), createdUser.getId());
        String refreshToken = jwtUtils.generateToken(createdUser.getUsername() + "_refresh", createdUser.getId());
        
        return new AuthResponse(accessToken, refreshToken, createdUser.getUsername(), createdUser.getId());
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
