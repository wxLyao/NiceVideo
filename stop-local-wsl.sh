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
echo -e "${BLUE}    停止NiceVideo微服务项目（WSL环境）${NC}"
echo -e "${BLUE}===============================================${NC}"

cd /mnt/c/Users/lyao/Documents/NiceVideo

# 服务列表
services=("eureka-server" "config-service" "gateway-service" "user-service" "auth-service")
stopped_count=0

echo -e "${YELLOW}🛑 停止所有服务...${NC}"

for service in "${services[@]}"; do
    pid_file="logs/$service.pid"
    
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        echo -e "${BLUE}🔄 停止 $service (PID: $pid)...${NC}"
        
        # 检查进程是否仍在运行
        if kill -0 "$pid" 2>/dev/null; then
            # 优雅停止
            kill -TERM "$pid" 2>/dev/null || true
            
            # 等待进程结束
            for i in {1..10}; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    break
                fi
                sleep 1
            done
            
            # 如果仍未结束，强制杀死
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "${YELLOW}  ⚠️  强制停止 $service...${NC}"
                kill -KILL "$pid" 2>/dev/null || true
            fi
            
            echo -e "${GREEN}  ✅ $service 已停止${NC}"
            ((stopped_count++))
        else
            echo -e "${YELLOW}  ⚠️  $service 进程已不存在${NC}"
        fi
        
        # 删除PID文件
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}  ⚠️  $service 没有PID文件${NC}"
    fi
done

echo
echo -e "${YELLOW}🧹 清理端口占用...${NC}"

# 清理可能残留的Java进程
ports=(8761 8888 8080 8081 8082)
for port in "${ports[@]}"; do
    # 查找占用端口的进程
    pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pid" ]; then
        echo -e "${BLUE}🔄 清理端口 $port (PID: $pid)...${NC}"
        kill -KILL "$pid" 2>/dev/null || true
        echo -e "${GREEN}  ✅ 端口 $port 已清理${NC}"
    fi
done

echo
echo -e "${YELLOW}📊 检查剩余进程...${NC}"

# 检查是否还有相关的Java进程
java_processes=$(ps aux | grep java | grep -E "(eureka|config|gateway|user|auth)" | grep -v grep || true)
if [ -n "$java_processes" ]; then
    echo -e "${YELLOW}⚠️  发现残留的Java进程:${NC}"
    echo "$java_processes" | sed 's/^/  /'
    
    # 询问是否强制清理
    read -p "是否强制清理所有相关Java进程？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🧹 强制清理Java进程...${NC}"
        ps aux | grep java | grep -E "(eureka|config|gateway|user|auth)" | grep -v grep | awk '{print $2}' | xargs -r kill -KILL
        echo -e "${GREEN}✅ 清理完成${NC}"
    fi
else
    echo -e "${GREEN}✅ 没有发现残留进程${NC}"
fi

echo
echo -e "${BLUE}📁 日志文件状态：${NC}"
if [ -d "logs" ]; then
    log_files=$(ls logs/*.log 2>/dev/null || true)
    if [ -n "$log_files" ]; then
        echo -e "${YELLOW}📋 可用的日志文件:${NC}"
        ls -la logs/*.log | sed 's/^/  /'
        echo
        echo -e "${BLUE}💡 查看日志命令: ${YELLOW}tail -f logs/[service_name].log${NC}"
        echo -e "${BLUE}💡 清理日志命令: ${YELLOW}rm -rf logs/*${NC}"
    else
        echo -e "${YELLOW}📋 没有找到日志文件${NC}"
    fi
else
    echo -e "${YELLOW}📋 日志目录不存在${NC}"
fi

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}             服务已停止！${NC}"
echo -e "${GREEN}===============================================${NC}"
echo
echo -e "${BLUE}📊 停止总结：${NC}"
echo -e "  成功停止: ${GREEN}$stopped_count${NC} 个服务"

echo
echo -e "${BLUE}🚀 重新启动命令：${NC}"
echo -e "    ${YELLOW}./start-local-wsl.sh${NC}"

echo
echo -e "${GREEN}🎉 所有服务已成功停止！${NC}"
