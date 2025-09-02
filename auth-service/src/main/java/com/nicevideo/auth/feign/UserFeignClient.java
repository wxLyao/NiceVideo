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
@FeignClient(name = "user-service")
public interface UserFeignClient {
    
    /**
     * 根据用户名查询用户
     */
    @GetMapping("/user/username/{username}")
    Result<UserDto> getByUsername(@PathVariable("username") String username);
    
    /**
     * 创建用户
     */
    @PostMapping("/user")
    Result<UserDto> createUser(@RequestBody UserDto user);
}
