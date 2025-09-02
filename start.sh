#!/bin/bash

echo "开始构建NiceVideo微服务项目..."

# 构建所有模块
echo "1. 构建Maven项目..."
mvn clean package -DskipTests

echo "2. 启动Docker容器..."
cd docker
docker-compose up -d

echo "3. 等待服务启动..."
sleep 30

echo "4. 检查服务状态..."
docker-compose ps

echo "5. 服务访问地址："
echo "   Eureka服务注册中心: http://localhost:8761"
echo "   配置中心: http://localhost:8888"
echo "   API网关: http://localhost:8080"
echo "   用户服务: http://localhost:8081"
echo "   认证服务: http://localhost:8082"

echo "6. API测试："
echo "   用户注册: POST http://localhost:8080/api/auth/register"
echo "   用户登录: POST http://localhost:8080/api/auth/login"
echo "   获取用户列表: GET http://localhost:8080/api/user/user/list"

echo "项目启动完成！"



