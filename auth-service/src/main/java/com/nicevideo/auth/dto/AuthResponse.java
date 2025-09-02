package com.nicevideo.auth.dto;

import lombok.Data;

/**
 * 认证响应DTO
 */
@Data
public class AuthResponse {
    
    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private Long expiresIn;
    private String username;
    private Long userId;
    
    public AuthResponse(String accessToken, String refreshToken, String username, Long userId) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.tokenType = "Bearer";
        this.expiresIn = 86400L;
        this.username = username;
        this.userId = userId;
    }
}



