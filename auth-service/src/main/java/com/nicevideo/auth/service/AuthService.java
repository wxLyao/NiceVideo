package com.nicevideo.auth.service;

import com.nicevideo.auth.dto.AuthResponse;
import com.nicevideo.auth.dto.LoginRequest;
import com.nicevideo.auth.dto.RegisterRequest;

/**
 * 认证服务接口
 */
public interface AuthService {
    
    /**
     * 用户登录
     */
    AuthResponse login(LoginRequest request);
    
    /**
     * 用户注册
     */
    AuthResponse register(RegisterRequest request);
    
    /**
     * 刷新Token
     */
    AuthResponse refreshToken(String refreshToken);
    
    /**
     * 验证Token
     */
    Boolean validateToken(String token);
}
