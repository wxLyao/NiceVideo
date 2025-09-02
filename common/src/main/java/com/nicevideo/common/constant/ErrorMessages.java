package com.nicevideo.common.constant;

/**
 * 错误信息常量
 */
public class ErrorMessages {
    
    // 用户相关错误信息
    public static final String USER_USERNAME_EXISTS = "用户名已存在";
    public static final String USER_EMAIL_EXISTS = "邮箱已被使用";
    public static final String USER_PHONE_EXISTS = "手机号已被使用";
    public static final String USER_NOT_FOUND = "用户不存在";
    public static final String USER_USERNAME_OR_PASSWORD_ERROR = "用户名或密码错误";
    
    // 认证相关错误信息
    public static final String AUTH_REGISTER_FAILED = "注册失败";
    public static final String AUTH_LOGIN_FAILED = "登录失败";
    public static final String AUTH_TOKEN_INVALID = "Token无效";
    public static final String AUTH_TOKEN_EXPIRED = "Token已过期";
    
    // 系统相关错误信息
    public static final String SYSTEM_ERROR = "系统异常，请联系管理员";
    public static final String PARAMETER_VALIDATION_ERROR = "参数校验失败";
}

