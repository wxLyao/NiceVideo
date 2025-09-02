package com.nicevideo.auth.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户DTO类
 */
@Data
public class UserDto {
    
    private Long id;
    private String username;
    private String password;
    private String email;
    private String phone;
    private String nickname;
    private String avatar;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}


