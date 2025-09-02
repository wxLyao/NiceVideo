package com.nicevideo.user.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.nicevideo.common.result.Result;
import com.nicevideo.user.entity.User;
import com.nicevideo.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

/**
 * 用户控制器
 */
@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {
    
    private final UserService userService;
    
    /**
     * 分页查询用户列表
     */
    @GetMapping("/list")
    public Result<Page<User>> list(@RequestParam(defaultValue = "1") Integer current,
                                   @RequestParam(defaultValue = "10") Integer size,
                                   @RequestParam(required = false) String username,
                                   @RequestParam(required = false) String email) {
        Page<User> page = new Page<>(current, size);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(username != null, User::getUsername, username)
                .like(email != null, User::getEmail, email)
                .orderByDesc(User::getCreateTime);
        
        Page<User> result = userService.page(page, wrapper);
        return Result.success(result);
    }
    
    /**
     * 根据ID查询用户
     */
    @GetMapping("/{id}")
    public Result<User> getById(@PathVariable Long id) {
        User user = userService.getById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }
        return Result.success(user);
    }
    
    /**
     * 创建用户
     */
    @PostMapping
    public Result<User> create(@Valid @RequestBody User user) {
        User createdUser = userService.createUser(user);
        return Result.success(createdUser);
    }
    
    /**
     * 更新用户
     */
    @PutMapping("/{id}")
    public Result<User> update(@PathVariable Long id, @Valid @RequestBody User user) {
        user.setId(id);
        User updatedUser = userService.updateUser(user);
        return Result.success(updatedUser);
    }
    
    /**
     * 删除用户
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userService.deleteUser(id);
        return Result.success();
    }
    
    /**
     * 根据用户名查询用户
     */
    @GetMapping("/username/{username}")
    public Result<User> getByUsername(@PathVariable String username) {
        User user = userService.getByUsername(username);
        return Result.success(user);
    }

    /**
     * 根据邮箱查询用户
     */
    @GetMapping("/email/{email}")
    public Result<User> getByEmail(@PathVariable String email) {
        User user = userService.getByEmail(email);
        return Result.success(user);
    }

    /**
     * 根据手机号查询用户
     */
    @GetMapping("/phone/{phone}")
    public Result<User> getByPhone(@PathVariable String phone) {
        User user = userService.getByPhone(phone);
        return Result.success(user);
    }
}

