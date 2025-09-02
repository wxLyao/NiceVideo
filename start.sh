#!/bin/bash

# 统一Linux启动脚本（Docker方式）
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  启动 NiceVideo 微服务项目（Linux + Docker）${NC}"
echo -e "${BLUE}===============================================${NC}"

# 0) 目录校验
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

# 1) Docker/Compose 检查
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}❌ 未检测到 docker，请先安装 Docker${NC}"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker 守护进程未运行，请先启动 Docker${NC}"
  exit 1
fi
if ! command -v docker-compose >/dev/null 2>&1; then
  # 尝试使用 Docker Compose v2 插件
  if docker compose version >/dev/null 2>&1; then
    docker_compose() { docker compose "$@"; }
    export -f docker_compose
    alias docker-compose='docker_compose'
  else
    echo -e "${YELLOW}🔄 未检测到 docker-compose，尝试安装（需要sudo）...${NC}"
    sudo curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi
fi

# 2) Maven 构建
echo -e "${YELLOW}[1/4] 构建 Maven 项目...${NC}"
export MAVEN_OPTS="-Xmx1024m"
mvn -q -T 1C clean package -DskipTests || { echo -e "${RED}❌ Maven 构建失败${NC}"; exit 1; }
echo -e "${GREEN}✅ Maven 构建完成${NC}"

# 3) 启动 Docker 容器
echo -e "${YELLOW}[2/4] 启动 Docker 容器...${NC}"
cd docker
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

docker-compose up -d --build || { echo -e "${RED}❌ Docker 容器启动失败${NC}"; exit 1; }

echo -e "${YELLOW}[3/4] 等待服务健康检查...${NC}"
for i in {1..30}; do
  # 若所有需要健康检查的容器都 healthy 则提前结束
  unhealthy=$(docker ps --filter 'name=nicevideo-' --format '{{.Names}}' | xargs -r -I{} docker inspect --format='{{.Name}}={{.State.Health.Status}}' {} 2>/dev/null | grep -E '=unhealthy|=starting' || true)
  if [ -z "$unhealthy" ]; then
    break
  fi
  echo -n "."; sleep 3
done

# 4) 展示状态与访问信息
echo
echo -e "${BLUE}📊 服务状态：${NC}"
docker-compose ps

echo
echo -e "${BLUE}🏥 健康检查：${NC}"
services=(eureka-server config-service gateway-service user-service auth-service)
for s in "${services[@]}"; do
  st=$(docker inspect --format='{{.State.Health.Status}}' "nicevideo-$s" 2>/dev/null || echo 'unknown')
  case "$st" in
    healthy)   echo -e "  ${GREEN}✅ $s: 健康${NC}";;
    starting)  echo -e "  ${YELLOW}🔄 $s: 启动中${NC}";;
    unhealthy) echo -e "  ${RED}❌ $s: 不健康${NC}";;
    *)         echo -e "  ${YELLOW}❓ $s: 状态未知${NC}";;
  esac
done

echo
echo -e "${BLUE}🌐 服务访问地址：${NC}"
echo -e "    📍 Eureka:     ${YELLOW}http://localhost:8761${NC}"
echo -e "    ⚙️  Config:     ${YELLOW}http://localhost:8888${NC}"
echo -e "    🚪 Gateway:    ${YELLOW}http://localhost:8080${NC}"
echo -e "    👤 用户服务经网关:  ${YELLOW}http://localhost:8080/api/user/**${NC}"
echo -e "    🔐 认证服务经网关:  ${YELLOW}http://localhost:8080/api/auth/**${NC}"

echo
echo -e "${BLUE}🧪 API 示例：${NC}"
echo -e "    注册: ${YELLOW}POST /api/auth/register${NC}"
echo -e "    登录: ${YELLOW}POST /api/auth/login${NC}"
echo -e "    查用户: ${YELLOW}GET  /api/user/username/{name}${NC}"

echo
echo -e "${GREEN}🎉 项目启动完成！${NC}"



