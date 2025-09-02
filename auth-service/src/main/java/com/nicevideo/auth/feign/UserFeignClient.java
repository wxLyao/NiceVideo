package com.nicevideo.auth.feign;

import com.nicevideo.auth.dto.UserDto;
import com.nicevideo.common.result.Result;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

/**
 * 用户服务Feign客户端
 */
@FeignClient(name = "user-service", configuration = com.nicevideo.auth.config.FeignConfig.class)
public interface UserFeignClient {
    
    /**
     * 根据用户名查询用户
     */
    @GetMapping("/user/username/{username}")
    Result<Object> getByUsername(@PathVariable("username") String username);

    /**
     * 根据邮箱查询用户
     */
    @GetMapping("/user/email/{email}")
    Result<Object> getByEmail(@PathVariable("email") String email);

    /**
     * 根据手机号查询用户
     */
    @GetMapping("/user/phone/{phone}")
    Result<Object> getByPhone(@PathVariable("phone") String phone);
    
    /**
     * 创建用户
     */
    @PostMapping("/user")
    Result<Object> createUser(@RequestBody UserDto user);
}
