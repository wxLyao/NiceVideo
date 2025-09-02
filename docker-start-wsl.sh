#!/bin/bash

# WSL环境下启动NiceVideo微服务项目
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      启动NiceVideo微服务项目（WSL + Docker）${NC}"
echo -e "${BLUE}===============================================${NC}"

# 检查是否在WSL环境中
if [[ ! -f /proc/version ]] || ! grep -q "microsoft" /proc/version 2>/dev/null; then
    echo -e "${YELLOW}⚠️  警告：检测到可能不在WSL环境中${NC}"
    echo -e "${YELLOW}   建议在WSL2中运行此脚本以获得最佳性能${NC}"
fi

echo
echo -e "${YELLOW}[1/6] 检查Docker环境...${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 错误：Docker未安装${NC}"
    echo -e "${RED}   请在WSL中安装Docker：${NC}"
    echo -e "${RED}   curl -fsSL https://get.docker.com -o get-docker.sh${NC}"
    echo -e "${RED}   sudo sh get-docker.sh${NC}"
    exit 1
fi

# 检查Docker服务是否运行
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}🔄 Docker服务未运行，尝试启动...${NC}"
    
    # 检查是否可以使用systemd
    if command -v systemctl &> /dev/null; then
        sudo systemctl start docker
    else
        # 在某些WSL环境中，可能需要手动启动Docker守护进程
        echo -e "${YELLOW}   请确保Docker Desktop在Windows中运行，或手动启动Docker守护进程${NC}"
        echo -e "${YELLOW}   Windows Docker Desktop设置中启用"Use the WSL 2 based engine"${NC}"
    fi
    
    # 再次检查
    sleep 3
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ 错误：无法启动Docker服务${NC}"
        echo -e "${RED}   请确保：${NC}"
        echo -e "${RED}   1. Docker Desktop在Windows中运行${NC}"
        echo -e "${RED}   2. WSL2集成已启用${NC}"
        echo -e "${RED}   3. 当前WSL发行版已在Docker Desktop中启用${NC}"
        exit 1
    fi
fi

# 检查Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}🔄 Docker Compose未安装，正在安装...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo -e "${GREEN}✅ Docker环境检查通过${NC}"

echo
echo -e "${YELLOW}[2/6] 检查Java和Maven环境...${NC}"

# 检查Java
if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}🔄 Java未安装，正在安装OpenJDK 11...${NC}"
    sudo apt update
    sudo apt install -y openjdk-11-jdk
fi

# 检查Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${YELLOW}🔄 Maven未安装，正在安装...${NC}"
    sudo apt update
    sudo apt install -y maven
fi

echo -e "${GREEN}✅ Java和Maven环境检查通过${NC}"

echo
echo -e "${YELLOW}[3/6] 停止并清理现有容器...${NC}"
cd docker
docker-compose down -v --remove-orphans 2>/dev/null || true
docker system prune -f >/dev/null 2>&1 || true

echo
echo -e "${YELLOW}[4/6] 构建Maven项目...${NC}"
cd ..

# 设置Maven选项以优化WSL性能
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m"

mvn clean package -DskipTests -q -T 1C
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 错误：Maven构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Maven构建完成${NC}"

echo
echo -e "${YELLOW}[5/6] 启动Docker容器...${NC}"
cd docker

# 在WSL中，可能需要设置一些环境变量
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

docker-compose up -d --build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 错误：Docker容器启动失败${NC}"
    exit 1
fi

echo
echo -e "${YELLOW}[6/6] 等待服务启动完成...${NC}"

# 等待服务健康检查通过
echo -e "${BLUE}正在等待服务健康检查...${NC}"
for i in {1..30}; do
    if docker-compose ps | grep -q "healthy"; then
        break
    fi
    echo -n "."
    sleep 5
done
echo

echo
echo -e "${BLUE}📊 服务状态检查：${NC}"
docker-compose ps

# 检查服务健康状态
echo
echo -e "${BLUE}🏥 健康检查状态：${NC}"
services=("eureka-server" "config-service" "gateway-service" "user-service" "auth-service")
for service in "${services[@]}"; do
    health=$(docker inspect --format='{{.State.Health.Status}}' "nicevideo-$service" 2>/dev/null || echo "unknown")
    case $health in
        "healthy")
            echo -e "  ${GREEN}✅ $service: 健康${NC}"
            ;;
        "unhealthy")
            echo -e "  ${RED}❌ $service: 不健康${NC}"
            ;;
        "starting")
            echo -e "  ${YELLOW}🔄 $service: 启动中${NC}"
            ;;
        *)
            echo -e "  ${YELLOW}❓ $service: 状态未知${NC}"
            ;;
    esac
done

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}             服务启动完成！${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
echo -e "${BLUE}🌐 服务访问地址：${NC}"
echo -e "    📍 Eureka服务注册中心: ${YELLOW}http://localhost:8761${NC}"
echo -e "    ⚙️  配置中心:         ${YELLOW}http://localhost:8888${NC}"
echo -e "    🚪 API网关:          ${YELLOW}http://localhost:8080${NC}"
echo -e "    👤 用户服务:         ${YELLOW}http://localhost:8081${NC}"
echo -e "    🔐 认证服务:         ${YELLOW}http://localhost:8082${NC}"
echo
echo -e "${BLUE}🧪 API测试示例：${NC}"
echo -e "    注册用户: ${YELLOW}POST http://localhost:8080/api/auth/register${NC}"
echo -e "    用户登录: ${YELLOW}POST http://localhost:8080/api/auth/login${NC}"
echo -e "    用户列表: ${YELLOW}GET  http://localhost:8080/api/user/user/list${NC}"
echo
echo -e "${BLUE}🔧 常用命令：${NC}"
echo -e "    查看日志: ${YELLOW}docker-compose logs -f [service_name]${NC}"
echo -e "    停止服务: ${YELLOW}docker-compose down${NC}"
echo -e "    重启服务: ${YELLOW}docker-compose restart [service_name]${NC}"
echo -e "    进入容器: ${YELLOW}docker exec -it nicevideo-[service_name] bash${NC}"
echo
echo -e "${BLUE}📊 性能监控：${NC}"
echo -e "    容器资源: ${YELLOW}docker stats${NC}"
echo -e "    系统信息: ${YELLOW}docker system df${NC}"
echo

# 询问是否自动测试API
read -p "是否立即测试API接口？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🧪 开始API测试...${NC}"
    
    # 等待服务完全启动
    sleep 10
    
    # 测试注册API
    echo -e "${YELLOW}测试用户注册...${NC}"
    curl -s -X POST http://localhost:8080/api/auth/register \
        -H "Content-Type: application/json" \
        -d '{
            "username": "wsltest",
            "password": "123456",
            "email": "wsltest@example.com",
            "phone": "13900139000",
            "nickname": "WSL测试用户"
        }' | jq . || echo "注册测试完成"
    
    echo
    echo -e "${YELLOW}测试用户登录...${NC}"
    curl -s -X POST http://localhost:8080/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{
            "username": "wsltest",
            "password": "123456"
        }' | jq . || echo "登录测试完成"
fi

echo
echo -e "${GREEN}🎉 NiceVideo项目已成功启动！${NC}"
