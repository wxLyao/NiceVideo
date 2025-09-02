# NiceVideo 微服务 API 文档

## 概述

NiceVideo是一个基于Spring Cloud的微服务架构项目，包含用户认证、用户管理等功能。

## 服务架构

- **Eureka Server**: 服务注册中心 (端口: 8761)
- **Config Service**: 配置中心 (端口: 8888)
- **Gateway Service**: API网关 (端口: 8080)
- **User Service**: 用户管理服务 (端口: 8081)
- **Auth Service**: 认证服务 (端口: 8082)

## API 接口

### 1. 用户认证

#### 1.1 用户注册
- **URL**: `POST /api/auth/register`
- **描述**: 用户注册
- **请求体**:
```json
{
    "username": "testuser",
    "password": "123456",
    "email": "test@example.com",
    "phone": "13800138000",
    "nickname": "测试用户"
}
```
- **响应**:
```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
        "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
        "tokenType": "Bearer",
        "expiresIn": 86400,
        "username": "testuser",
        "userId": 1
    }
}
```

#### 1.2 用户登录
- **URL**: `POST /api/auth/login`
- **描述**: 用户登录
- **请求体**:
```json
{
    "username": "testuser",
    "password": "123456"
}
```
- **响应**: 同注册接口

#### 1.3 刷新Token
- **URL**: `POST /api/auth/refresh`
- **描述**: 刷新访问令牌
- **参数**: `refreshToken` (查询参数)
- **响应**: 同注册接口

#### 1.4 验证Token
- **URL**: `GET /api/auth/validate`
- **描述**: 验证令牌有效性
- **参数**: `token` (查询参数)
- **响应**:
```json
{
    "code": 200,
    "message": "操作成功",
    "data": true
}
```

### 2. 用户管理

#### 2.1 获取用户列表
- **URL**: `GET /api/user/user/list`
- **描述**: 分页获取用户列表
- **参数**:
  - `current`: 当前页 (默认: 1)
  - `size`: 每页大小 (默认: 10)
  - `username`: 用户名模糊查询 (可选)
  - `email`: 邮箱模糊查询 (可选)
- **响应**:
```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "records": [
            {
                "id": 1,
                "username": "admin",
                "email": "admin@nicevideo.com",
                "phone": "13800138000",
                "nickname": "管理员",
                "status": 1,
                "createTime": "2024-01-01T00:00:00"
            }
        ],
        "total": 1,
        "size": 10,
        "current": 1
    }
}
```

#### 2.2 获取用户详情
- **URL**: `GET /api/user/user/{id}`
- **描述**: 根据ID获取用户详情
- **响应**:
```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "id": 1,
        "username": "admin",
        "email": "admin@nicevideo.com",
        "phone": "13800138000",
        "nickname": "管理员",
        "status": 1,
        "createTime": "2024-01-01T00:00:00"
    }
}
```

#### 2.3 创建用户
- **URL**: `POST /api/user/user`
- **描述**: 创建新用户
- **请求体**: 同注册接口
- **响应**:
```json
{
    "code": 200,
    "message": "操作成功",
    "data": null
}
```

#### 2.4 更新用户
- **URL**: `PUT /api/user/user/{id}`
- **描述**: 更新用户信息
- **请求体**: 用户信息
- **响应**: 同创建用户

#### 2.5 删除用户
- **URL**: `DELETE /api/user/user/{id}`
- **描述**: 删除用户
- **响应**: 同创建用户

## 错误码说明

- `200`: 操作成功
- `400`: 请求参数错误
- `401`: 未授权
- `403`: 禁止访问
- `404`: 资源不存在
- `500`: 服务器内部错误

## 测试账号

系统预置了两个测试账号：

1. **管理员账号**
   - 用户名: `admin`
   - 密码: `123456`
   - 邮箱: `admin@nicevideo.com`

2. **测试账号**
   - 用户名: `test`
   - 密码: `123456`
   - 邮箱: `test@nicevideo.com`

## 部署说明

### 环境要求
- JDK 11+
- Maven 3.6+
- Docker & Docker Compose
- MySQL 8.0+

### 启动步骤
1. 克隆项目
2. 执行 `chmod +x start.sh`
3. 执行 `./start.sh`

### 访问地址
- Eureka服务注册中心: http://localhost:8761
- API网关: http://localhost:8080
- 用户服务: http://localhost:8081
- 认证服务: http://localhost:8082


