#!/bin/bash

# WSL环境下本地启动NiceVideo微服务项目
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    本地启动NiceVideo微服务项目（WSL环境）${NC}"
echo -e "${BLUE}===============================================${NC}"

echo
echo -e "${YELLOW}[1/5] 检查Java和Maven环境...${NC}"

# 检查Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java未安装，正在安装OpenJDK 11...${NC}"
    sudo apt update
    sudo apt install -y openjdk-11-jdk
fi

java_version=$(java -version 2>&1 | head -n 1)
echo -e "${GREEN}✅ Java环境: $java_version${NC}"

# 检查Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${YELLOW}🔄 Maven未安装，正在安装...${NC}"
    sudo apt update
    sudo apt install -y maven
fi

mvn_version=$(mvn --version | head -n 1)
echo -e "${GREEN}✅ Maven环境: $mvn_version${NC}"

echo
echo -e "${YELLOW}[2/5] 构建项目...${NC}"

# 设置Maven选项
export MAVEN_OPTS="-Xmx1024m"

cd /mnt/c/Users/lyao/Documents/NiceVideo
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 错误：Maven构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Maven构建完成${NC}"

echo
echo -e "${YELLOW}[3/5] 检查端口占用...${NC}"

# 检查关键端口是否被占用
ports=(8761 8888 8080 8081 8082)
for port in "${ports[@]}"; do
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${YELLOW}⚠️  端口 $port 已被占用，尝试杀死占用进程...${NC}"
        # 尝试找到并杀死占用端口的Java进程
        pid=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
            echo -e "${GREEN}✅ 已清理端口 $port${NC}"
        fi
    fi
done

echo
echo -e "${YELLOW}[4/5] 启动服务...${NC}"

# 创建日志目录
mkdir -p logs

# 服务启动函数
start_service() {
    local service_name=$1
    local jar_path=$2
    local port=$3
    local profile=${4:-"local"}
    
    echo -e "${BLUE}🚀 启动 $service_name (端口:$port)...${NC}"
    
    # 启动服务并将输出重定向到日志文件
    nohup java -jar \
        -Dspring.profiles.active=$profile \
        -Dserver.port=$port \
        -Djava.awt.headless=true \
        -Xmx512m \
        "$jar_path" \
        > "logs/$service_name.log" 2>&1 &
    
    local pid=$!
    echo $pid > "logs/$service_name.pid"
    
    # 等待服务启动
    echo -e "${YELLOW}⏳ 等待 $service_name 启动...${NC}"
    for i in {1..30}; do
        if curl -s "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name 启动成功 (PID: $pid)${NC}"
            return 0
        fi
        sleep 2
        echo -n "."
    done
    
    echo
    echo -e "${RED}❌ $service_name 启动超时，请检查日志: logs/$service_name.log${NC}"
    return 1
}

# 按顺序启动服务
echo -e "${BLUE}📋 服务启动序列：${NC}"

# 1. Eureka Server
start_service "eureka-server" "eureka-server/target/eureka-server-1.0.0.jar" 8761

# 等待Eureka完全启动
sleep 10

# 2. Config Service
start_service "config-service" "config-service/target/config-service-1.0.0.jar" 8888

# 等待Config Service启动
sleep 5

# 3. User Service
start_service "user-service" "user-service/target/user-service-1.0.0.jar" 8081

# 4. Auth Service
start_service "auth-service" "auth-service/target/auth-service-1.0.0.jar" 8082

# 5. Gateway Service
start_service "gateway-service" "gateway-service/target/gateway-service-1.0.0.jar" 8080

echo
echo -e "${YELLOW}[5/5] 验证服务状态...${NC}"

sleep 10

# 检查所有服务状态
services=("eureka-server:8761" "config-service:8888" "user-service:8081" "auth-service:8082" "gateway-service:8080")
healthy_count=0

for service_info in "${services[@]}"; do
    service_name=$(echo $service_info | cut -d':' -f1)
    port=$(echo $service_info | cut -d':' -f2)
    
    if curl -s "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $service_name (端口:$port) - 健康${NC}"
        ((healthy_count++))
    else
        echo -e "  ${RED}❌ $service_name (端口:$port) - 不健康${NC}"
        # 显示最近的日志
        if [ -f "logs/$service_name.log" ]; then
            echo -e "    ${YELLOW}最近日志:${NC}"
            tail -5 "logs/$service_name.log" | sed 's/^/    /'
        fi
    fi
done

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}             服务启动完成！${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
echo -e "${BLUE}📊 状态总结：${NC}"
echo -e "  健康服务: ${GREEN}$healthy_count${NC}/${#services[@]}"

if [ $healthy_count -eq ${#services[@]} ]; then
    echo -e "  ${GREEN}🎉 所有服务运行正常！${NC}"
else
    echo -e "  ${YELLOW}⚠️  部分服务存在问题，请检查日志${NC}"
fi

echo
echo -e "${BLUE}🌐 服务访问地址：${NC}"
echo -e "    📍 Eureka服务注册中心: ${YELLOW}http://localhost:8761${NC}"
echo -e "    ⚙️  配置中心:         ${YELLOW}http://localhost:8888${NC}"
echo -e "    🚪 API网关:          ${YELLOW}http://localhost:8080${NC}"
echo -e "    👤 用户服务:         ${YELLOW}http://localhost:8081${NC}"
echo -e "    🔐 认证服务:         ${YELLOW}http://localhost:8082${NC}"

echo
echo -e "${BLUE}🔧 管理命令：${NC}"
echo -e "    查看日志: ${YELLOW}tail -f logs/[service_name].log${NC}"
echo -e "    停止服务: ${YELLOW}./stop-local-wsl.sh${NC}"
echo -e "    重启服务: ${YELLOW}./restart-local-wsl.sh${NC}"

echo
echo -e "${BLUE}🧪 测试API：${NC}"
echo -e "    用户注册: ${YELLOW}curl -X POST http://localhost:8080/api/auth/register -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"123456\",\"email\":\"test@example.com\"}'${NC}"

echo
echo -e "${GREEN}🎉 NiceVideo项目已成功启动！${NC}"
