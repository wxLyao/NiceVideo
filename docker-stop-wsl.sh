#!/bin/bash

# WSL环境下停止NiceVideo微服务项目
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      停止NiceVideo微服务项目（WSL + Docker）${NC}"
echo -e "${BLUE}===============================================${NC}"

echo
echo -e "${YELLOW}[1/4] 停止所有服务容器...${NC}"
cd docker
docker-compose down

echo
echo -e "${YELLOW}[2/4] 清理容器、网络和数据卷...${NC}"
docker-compose down -v --remove-orphans

echo
echo -e "${YELLOW}[3/4] 显示剩余容器状态...${NC}"
echo -e "${BLUE}NiceVideo相关容器：${NC}"
docker ps -a --filter "name=nicevideo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo
echo -e "${BLUE}所有容器状态：${NC}"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo
echo -e "${YELLOW}[4/4] 系统资源状态...${NC}"
echo -e "${BLUE}Docker系统信息：${NC}"
docker system df

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}             服务已停止！${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
echo -e "${BLUE}🔧 可选清理操作：${NC}"
echo -e "    完全清理镜像:     ${YELLOW}docker-compose down -v --rmi all${NC}"
echo -e "    清理未使用数据卷: ${YELLOW}docker volume prune -f${NC}"
echo -e "    清理未使用网络:   ${YELLOW}docker network prune -f${NC}"
echo -e "    清理构建缓存:     ${YELLOW}docker builder prune -f${NC}"
echo -e "    完全系统清理:     ${YELLOW}docker system prune -a -f${NC}"

# 询问是否执行完全清理
echo
read -p "是否执行完全清理（删除所有相关镜像和缓存）？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🧹 执行完全清理...${NC}"
    
    # 停止并删除所有相关容器和镜像
    docker-compose down -v --rmi all --remove-orphans
    
    # 清理未使用的资源
    docker volume prune -f
    docker network prune -f
    docker builder prune -f
    
    echo -e "${GREEN}✅ 完全清理完成${NC}"
    
    # 显示清理后的状态
    echo
    echo -e "${BLUE}清理后的系统状态：${NC}"
    docker system df
fi

echo
echo -e "${GREEN}🎉 NiceVideo项目已完全停止！${NC}"
