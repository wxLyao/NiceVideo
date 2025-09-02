#!/bin/bash

# Docker服务健康检查脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         NiceVideo服务健康检查${NC}"
echo -e "${BLUE}===============================================${NC}"

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker服务未运行${NC}"
    exit 1
fi

cd docker

# 检查服务是否运行
echo -e "${YELLOW}📊 检查容器状态...${NC}"
docker-compose ps

echo
echo -e "${YELLOW}🏥 健康检查详情...${NC}"

# 服务列表
services=("mysql" "eureka-server" "config-service" "gateway-service" "user-service" "auth-service")
healthy_count=0
total_count=${#services[@]}

for service in "${services[@]}"; do
    container_name="nicevideo-$service"
    
    # 检查容器是否存在并运行
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        # 获取健康状态
        if [ "$service" = "mysql" ]; then
            # MySQL特殊检查
            health_status=$(docker exec "$container_name" mysqladmin ping -h localhost -u root -p123456 2>/dev/null && echo "healthy" || echo "unhealthy")
        else
            # 其他服务使用Docker健康检查
            health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")
        fi
        
        case $health_status in
            "healthy")
                echo -e "  ${GREEN}✅ $service: 健康运行${NC}"
                ((healthy_count++))
                ;;
            "unhealthy")
                echo -e "  ${RED}❌ $service: 不健康${NC}"
                # 显示最近的健康检查日志
                echo -e "    ${YELLOW}最近日志:${NC}"
                docker logs --tail 5 "$container_name" 2>/dev/null | sed 's/^/    /'
                ;;
            "starting")
                echo -e "  ${YELLOW}🔄 $service: 启动中...${NC}"
                ;;
            "no-healthcheck")
                # 简单检查端口是否响应
                if [ "$service" = "eureka-server" ]; then
                    port=8761
                elif [ "$service" = "config-service" ]; then
                    port=8888
                elif [ "$service" = "gateway-service" ]; then
                    port=8080
                elif [ "$service" = "user-service" ]; then
                    port=8081
                elif [ "$service" = "auth-service" ]; then
                    port=8082
                fi
                
                if docker exec "$container_name" nc -z localhost $port 2>/dev/null; then
                    echo -e "  ${GREEN}✅ $service: 端口 $port 响应正常${NC}"
                    ((healthy_count++))
                else
                    echo -e "  ${RED}❌ $service: 端口 $port 无响应${NC}"
                fi
                ;;
            *)
                echo -e "  ${RED}❓ $service: 状态未知 ($health_status)${NC}"
                ;;
        esac
    else
        echo -e "  ${RED}❌ $service: 容器未运行${NC}"
    fi
done

echo
echo -e "${BLUE}📈 健康状态总结：${NC}"
echo -e "  健康服务: ${GREEN}$healthy_count${NC}/$total_count"

if [ $healthy_count -eq $total_count ]; then
    echo -e "  ${GREEN}🎉 所有服务运行正常！${NC}"
    exit_code=0
else
    echo -e "  ${YELLOW}⚠️  部分服务存在问题${NC}"
    exit_code=1
fi

echo
echo -e "${BLUE}🔗 服务端点检查：${NC}"

# 检查关键端点
endpoints=(
    "http://localhost:8761 Eureka服务注册中心"
    "http://localhost:8888/actuator/health 配置中心健康检查"
    "http://localhost:8080/actuator/health API网关健康检查"
    "http://localhost:8081/actuator/health 用户服务健康检查"
    "http://localhost:8082/actuator/health 认证服务健康检查"
)

for endpoint in "${endpoints[@]}"; do
    url=$(echo $endpoint | cut -d' ' -f1)
    name=$(echo $endpoint | cut -d' ' -f2-)
    
    if curl -s --max-time 5 "$url" &> /dev/null; then
        echo -e "  ${GREEN}✅ $name${NC}"
    else
        echo -e "  ${RED}❌ $name (URL: $url)${NC}"
        exit_code=1
    fi
done

echo
echo -e "${BLUE}💾 资源使用情况：${NC}"
echo -e "${YELLOW}Docker容器资源统计:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep nicevideo || echo "  无资源数据"

echo
echo -e "${BLUE}📁 数据卷使用情况：${NC}"
docker system df

echo
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ 健康检查完成 - 所有服务正常${NC}"
else
    echo -e "${YELLOW}⚠️  健康检查完成 - 发现问题，请检查日志${NC}"
    echo -e "${BLUE}💡 查看详细日志命令:${NC}"
    echo -e "    docker-compose logs -f [service_name]"
    echo -e "    docker logs [container_name]"
fi

echo -e "${BLUE}===============================================${NC}"

exit $exit_code
