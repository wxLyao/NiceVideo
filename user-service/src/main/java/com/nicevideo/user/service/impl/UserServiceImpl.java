package com.nicevideo.user.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.nicevideo.common.constant.ErrorMessages;
import com.nicevideo.common.exception.BusinessException;
import com.nicevideo.user.entity.User;
import com.nicevideo.user.mapper.UserMapper;
import com.nicevideo.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 用户服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {
    
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    @Override
    public User getByUsername(String username) {
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, username));
    }
    
    @Override
    public User getByEmail(String email) {
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getEmail, email));
    }
    
    @Override
    public User getByPhone(String phone) {
        return this.getOne(new LambdaQueryWrapper<User>()
                .eq(User::getPhone, phone));
    }
    
    @Override
    public User createUser(User user) {
        // 检查用户名唯一性
        if (StringUtils.hasText(user.getUsername())) {
            User existingUser = getByUsername(user.getUsername());
            if (existingUser != null) {
                throw new BusinessException(400, ErrorMessages.USER_USERNAME_EXISTS);
            }
        }
        
        // 检查邮箱唯一性
        if (StringUtils.hasText(user.getEmail())) {
            User userWithSameEmail = getByEmail(user.getEmail());
            if (userWithSameEmail != null) {
                throw new BusinessException(400, ErrorMessages.USER_EMAIL_EXISTS);
            }
        }
        
        // 检查手机号唯一性
        if (StringUtils.hasText(user.getPhone())) {
            User userWithSamePhone = getByPhone(user.getPhone());
            if (userWithSamePhone != null) {
                throw new BusinessException(400, ErrorMessages.USER_PHONE_EXISTS);
            }
        }
        
        // 加密密码
        if (StringUtils.hasText(user.getPassword())) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        
        // 设置默认状态
        user.setStatus(1);
        
        // 设置创建时间和更新时间（防止自动填充失效）
        if (user.getCreateTime() == null) {
            user.setCreateTime(java.time.LocalDateTime.now());
        }
        if (user.getUpdateTime() == null) {
            user.setUpdateTime(java.time.LocalDateTime.now());
        }
        
        this.save(user);
        return user;
    }
    
    @Override
    public User updateUser(User user) {
        User existingUser = this.getById(user.getId());
        if (existingUser == null) {
            throw new BusinessException(404, ErrorMessages.USER_NOT_FOUND);
        }
        
        // 检查用户名唯一性（排除自己）
        if (StringUtils.hasText(user.getUsername())) {
            User userWithSameUsername = getByUsername(user.getUsername());
            if (userWithSameUsername != null && !userWithSameUsername.getId().equals(user.getId())) {
                throw new BusinessException(400, ErrorMessages.USER_USERNAME_EXISTS);
            }
        }
        
        // 检查邮箱唯一性（排除自己）
        if (StringUtils.hasText(user.getEmail())) {
            User userWithSameEmail = getByEmail(user.getEmail());
            if (userWithSameEmail != null && !userWithSameEmail.getId().equals(user.getId())) {
                throw new BusinessException(400, ErrorMessages.USER_EMAIL_EXISTS);
            }
        }
        
        // 检查手机号唯一性（排除自己）
        if (StringUtils.hasText(user.getPhone())) {
            User userWithSamePhone = getByPhone(user.getPhone());
            if (userWithSamePhone != null && !userWithSamePhone.getId().equals(user.getId())) {
                throw new BusinessException(400, ErrorMessages.USER_PHONE_EXISTS);
            }
        }
        
        // 如果密码有变化，重新加密
        if (StringUtils.hasText(user.getPassword()) && !user.getPassword().equals(existingUser.getPassword())) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        
        this.updateById(user);
        return this.getById(user.getId());
    }
    
    @Override
    public void deleteUser(Long id) {
        this.removeById(id);
    }
}
