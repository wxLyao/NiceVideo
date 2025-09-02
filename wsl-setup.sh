#!/bin/bash

# WSL环境初始化脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         WSL环境初始化 - NiceVideo项目${NC}"
echo -e "${BLUE}===============================================${NC}"

# 检查是否在WSL环境中
if [[ ! -f /proc/version ]] || ! grep -q "microsoft" /proc/version 2>/dev/null; then
    echo -e "${RED}❌ 错误：此脚本需要在WSL环境中运行${NC}"
    exit 1
fi

echo -e "${GREEN}✅ WSL环境检测通过${NC}"

# 获取WSL版本信息
echo -e "${BLUE}WSL环境信息：${NC}"
cat /proc/version | grep -o "microsoft-standard.*" || echo "WSL环境"

echo
echo -e "${YELLOW}[1/5] 更新系统包...${NC}"
sudo apt update && sudo apt upgrade -y

echo
echo -e "${YELLOW}[2/5] 安装基础工具...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    htop \
    tree \
    vim \
    build-essential

echo
echo -e "${YELLOW}[3/5] 安装Java 11...${NC}"
if ! command -v java &> /dev/null; then
    sudo apt install -y openjdk-11-jdk
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> ~/.bashrc
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
else
    echo -e "${GREEN}✅ Java已安装: $(java -version 2>&1 | head -n 1)${NC}"
fi

echo
echo -e "${YELLOW}[4/5] 安装Maven...${NC}"
if ! command -v mvn &> /dev/null; then
    sudo apt install -y maven
else
    echo -e "${GREEN}✅ Maven已安装: $(mvn -version | head -n 1)${NC}"
fi

echo
echo -e "${YELLOW}[5/5] 配置Docker...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}安装Docker...${NC}"
    
    # 添加Docker的官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # 添加用户到docker组
    sudo usermod -aG docker $USER
    
    echo -e "${YELLOW}⚠️  需要重新登录WSL以应用Docker组权限${NC}"
else
    echo -e "${GREEN}✅ Docker已安装: $(docker --version)${NC}"
fi

# 安装Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BLUE}安装Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}✅ Docker Compose已安装: $(docker-compose --version)${NC}"
fi

echo
echo -e "${BLUE}设置脚本权限...${NC}"
chmod +x docker-start-wsl.sh
chmod +x docker-stop-wsl.sh
chmod +x start.sh

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}           WSL环境初始化完成！${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
echo -e "${BLUE}📋 安装总结：${NC}"
echo -e "    ✅ 系统更新完成"
echo -e "    ✅ 基础工具安装完成"
echo -e "    ✅ Java 11安装完成"
echo -e "    ✅ Maven安装完成"
echo -e "    ✅ Docker环境配置完成"
echo -e "    ✅ 脚本权限设置完成"

echo
echo -e "${BLUE}🚀 下一步操作：${NC}"
echo -e "    1. 重新启动WSL终端以应用权限变更"
echo -e "    2. 确保Windows Docker Desktop已启动并启用WSL2集成"
echo -e "    3. 运行 ${YELLOW}./docker-start-wsl.sh${NC} 启动项目"

echo
echo -e "${BLUE}💡 Windows Docker Desktop设置：${NC}"
echo -e "    1. 打开Docker Desktop"
echo -e "    2. 进入Settings > General"
echo -e "    3. 确保'Use the WSL 2 based engine'已启用"
echo -e "    4. 进入Settings > Resources > WSL Integration"
echo -e "    5. 启用当前WSL发行版的集成"

echo
echo -e "${BLUE}🔧 有用的命令：${NC}"
echo -e "    启动项目: ${YELLOW}./docker-start-wsl.sh${NC}"
echo -e "    停止项目: ${YELLOW}./docker-stop-wsl.sh${NC}"
echo -e "    查看日志: ${YELLOW}cd docker && docker-compose logs -f${NC}"
echo -e "    检查状态: ${YELLOW}cd docker && docker-compose ps${NC}"

echo
echo -e "${GREEN}🎉 环境准备就绪！${NC}"
