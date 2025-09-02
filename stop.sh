#!/bin/bash

# 统一Linux停止脚本（Docker方式）
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/docker"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  停止 NiceVideo 微服务项目（Linux + Docker）${NC}"
echo -e "${BLUE}===============================================${NC}"

echo -e "${YELLOW}[1/3] 停止服务容器...${NC}"
docker-compose down || true

echo -e "${YELLOW}[2/3] 清理残留资源...${NC}"
docker-compose down -v --remove-orphans || true

echo -e "${YELLOW}[3/3] 系统资源状态...${NC}"
echo -e "${BLUE}容器状态：${NC}"
docker ps -a --filter "name=nicevideo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "${BLUE}Docker系统信息：${NC}"
docker system df

echo
echo -e "${GREEN}🎉 服务已停止！${NC}"
