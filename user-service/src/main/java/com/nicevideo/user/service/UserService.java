package com.nicevideo.user.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.nicevideo.user.entity.User;

/**
 * 用户服务接口
 */
public interface UserService extends IService<User> {
    
    /**
     * 根据用户名查询用户
     */
    User getByUsername(String username);
    
    /**
     * 根据邮箱查询用户
     */
    User getByEmail(String email);
    
    /**
     * 根据手机号查询用户
     */
    User getByPhone(String phone);
    
    /**
     * 创建用户
     */
    User createUser(User user);
    
    /**
     * 更新用户
     */
    User updateUser(User user);
    
    /**
     * 删除用户
     */
    void deleteUser(Long id);
}


