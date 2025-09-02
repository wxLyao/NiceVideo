# NiceVideo

## 项目简介

NiceVideo是一个基于Spring Cloud的微服务架构项目，实现了完整的用户登录注册功能，采用现代化的技术栈和最佳实践。

## 项目架构

### 技术栈
- **后端框架**: Spring Boot 2.7.x
- **微服务框架**: Spring Cloud 2021.x
- **数据库**: MySQL 8.0
- **服务注册与发现**: Eureka Server
- **API网关**: Spring Cloud Gateway
- **配置中心**: Spring Cloud Config
- **安全认证**: Spring Security + JWT + OAuth2
- **密码加密**: BCrypt
- **容器化**: Docker

### 微服务模块
1. **auth-service**: 用户认证服务（登录注册）
2. **user-service**: 用户管理服务
3. **gateway-service**: API网关服务
4. **config-service**: 配置中心服务
5. **eureka-server**: 服务注册中心

### 项目结构
```
NiceVideo/
├── auth-service/          # 认证服务
├── user-service/          # 用户服务
├── gateway-service/       # 网关服务
├── config-service/        # 配置服务
├── eureka-server/         # 注册中心
├── common/                # 公共模块
├── docker/                # Docker配置
├── sql/                   # 数据库脚本
├── pom.xml                # 父POM
├── start.sh               # Linux启动脚本
├── start-windows.bat      # Windows启动脚本
├── stop-windows.bat       # Windows停止脚本
├── API.md                 # API文档
├── Windows部署指南.md     # Windows详细部署指南
└── README.md              # 项目说明
```

## 功能特性

### 用户认证
- ✅ 用户注册（支持用户名、邮箱、手机号）
- ✅ 用户登录（JWT Token认证）
- ✅ Token刷新机制
- ✅ Token验证
- ✅ 密码BCrypt加密

### 用户管理
- ✅ 用户信息CRUD操作
- ✅ 分页查询用户列表
- ✅ 用户状态管理
- ✅ 逻辑删除

### 微服务特性
- ✅ 服务注册与发现
- ✅ API网关路由
- ✅ 配置中心
- ✅ 服务间通信（Feign）
- ✅ 统一异常处理
- ✅ 统一响应格式

## 快速开始

### 环境要求
- JDK 11+
- Maven 3.6+
- MySQL 8.0+
- Docker & Docker Compose（可选）

### 部署方式

#### 方式一：Docker部署（推荐）

**🔧 环境初始化：**

Windows环境：
```powershell
# 运行环境设置脚本
.\Setup-Docker.ps1

# 或者，如果要使用WSL
.\Setup-Docker.ps1 -WSL
```

WSL环境（推荐）：
```bash
# 1. 进入WSL
wsl

# 2. 导航到项目目录
cd /mnt/c/Users/[用户名]/Documents/NiceVideo

# 3. 初始化WSL环境
chmod +x wsl-setup.sh
./wsl-setup.sh
```

**🚀 启动服务：**

WSL环境（推荐）：
```bash
# 启动所有服务
./docker-start-wsl.sh

# 健康检查
./docker-health-check.sh

# API测试
./docker-test-api.sh
```

Windows环境：
```batch
# 方式1：使用图形化脚本
docker-start-windows.bat

# 方式2：快速启动
quick-start.bat
```

Linux/Mac环境：
```bash
# 启动服务
chmod +x start.sh
./start.sh
```

#### 方式二：本地部署

**Linux/Mac环境：**
```bash
# 1. 构建项目
mvn clean package -DskipTests

# 2. 启动服务
./start.sh
```

**Windows环境：**
```bash
# 1. 构建项目
mvn clean package -DskipTests

# 2. 启动服务（推荐）
start-windows.bat

# 或者手动启动（详见Windows部署指南.md）
```

### 服务访问地址
- Eureka服务注册中心: http://localhost:8761
- API网关: http://localhost:8080
- 用户服务: http://localhost:8081
- 认证服务: http://localhost:8082

### API测试

#### 用户注册
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "123456",
    "email": "test@example.com",
    "phone": "13800138000",
    "nickname": "测试用户"
  }'
```

#### 用户登录
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "123456"
  }'
```

#### 获取用户列表
```bash
curl -X GET "http://localhost:8080/api/user/user/list?current=1&size=10"
```

## 配置说明

### 数据库配置
数据库配置文件位于各服务的`application.yml`中，默认配置：
- 数据库名: `nicevideo_user`
- 用户名: `root`
- 密码: `123456`
- 端口: `3306`

### JWT配置
JWT相关配置在认证服务的`application.yml`中：
```yaml
jwt:
  secret: nicevideo-jwt-secret-key-2024
  expiration: 86400  # 24小时
```

### 服务端口
- Eureka Server: 8761
- Config Service: 8888
- Gateway Service: 8080
- User Service: 8081
- Auth Service: 8082

## 开发指南

### 添加新服务
1. 在根目录创建新的服务模块
2. 在根`pom.xml`中添加模块
3. 创建对应的Dockerfile
4. 在`docker-compose.yml`中添加服务配置

### 自定义配置
1. 修改对应服务的`application.yml`
2. 如需外部配置，可配置Config Service的Git仓库

### 扩展功能
- 添加新的API接口
- 实现新的微服务模块
- 集成第三方服务（如Redis、RabbitMQ等）

## 部署说明

### 生产环境部署
1. 修改数据库配置为生产环境
2. 配置Config Service的Git仓库
3. 设置JWT密钥
4. 配置Docker镜像仓库
5. 使用Docker Swarm或Kubernetes进行容器编排

### 监控和日志
- 集成Spring Boot Actuator
- 配置日志收集（ELK Stack）
- 添加链路追踪（Zipkin）

## 常见问题

### Q: 服务启动失败
A: 检查端口是否被占用，数据库连接是否正常

### Q: 注册用户失败
A: 检查用户名是否已存在，数据库连接是否正常

### Q: 登录失败
A: 检查用户名密码是否正确，用户状态是否正常

### Q: Windows环境下如何启动？
A: 请参考 `Windows部署指南.md` 或使用 `start-windows.bat` 脚本

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交代码
4. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题，请提交Issue或联系项目维护者。