package com.nicevideo.auth.controller;

import com.nicevideo.auth.dto.AuthResponse;
import com.nicevideo.auth.dto.LoginRequest;
import com.nicevideo.auth.dto.RegisterRequest;
import com.nicevideo.auth.service.AuthService;
import com.nicevideo.common.result.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RequestMethod;

import javax.validation.Valid;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    
    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return Result.success(response);
    }
    
    /**
     * 用户注册
     */
    @PostMapping("/register")
    public Result<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return Result.success(response);
    }
    
    /**
     * 刷新Token
     */
    @PostMapping("/refresh")
    public Result<AuthResponse> refreshToken(@RequestParam String refreshToken) {
        AuthResponse response = authService.refreshToken(refreshToken);
        return Result.success(response);
    }
    
    /**
     * 验证Token (支持GET和POST方法)
     */
    @RequestMapping(value = "/validate", method = {RequestMethod.GET, RequestMethod.POST})
    public Result<Boolean> validateToken(@RequestParam String token) {
        boolean isValid = authService.validateToken(token);
        return Result.success(isValid);
    }
}


