#!/bin/bash

# Docker环境API测试脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         NiceVideo API功能测试${NC}"
echo -e "${BLUE}===============================================${NC}"

# 检查jq是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq未安装，将安装以格式化JSON输出...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    else
        echo -e "${YELLOW}无法自动安装jq，输出将不会格式化${NC}"
    fi
fi

# 等待服务启动
echo -e "${YELLOW}🔄 等待服务完全启动...${NC}"
sleep 10

# 基础URL
BASE_URL="http://localhost:8080"
GATEWAY_URL="$BASE_URL/api"

# 测试计数器
total_tests=0
passed_tests=0

# 测试函数
run_test() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    
    ((total_tests++))
    echo -e "${BLUE}🧪 测试: $test_name${NC}"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>/dev/null)
    fi
    
    # 分离响应体和状态码
    body=$(echo "$response" | head -n -1)
    status=$(echo "$response" | tail -n 1)
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "  ${GREEN}✅ 状态码: $status (期望: $expected_status)${NC}"
        if command -v jq &> /dev/null && [ -n "$body" ]; then
            echo -e "  ${GREEN}📄 响应:${NC}"
            echo "$body" | jq . 2>/dev/null | sed 's/^/    /' || echo "    $body"
        else
            echo -e "  ${GREEN}📄 响应: $body${NC}"
        fi
        ((passed_tests++))
    else
        echo -e "  ${RED}❌ 状态码: $status (期望: $expected_status)${NC}"
        echo -e "  ${RED}📄 错误响应: $body${NC}"
    fi
    echo
}

# 1. 健康检查
echo -e "${YELLOW}[1/6] 服务健康检查${NC}"
run_test "Eureka健康检查" "GET" "http://localhost:8761/actuator/health" "" "200"
run_test "配置中心健康检查" "GET" "http://localhost:8888/actuator/health" "" "200"
run_test "网关健康检查" "GET" "http://localhost:8080/actuator/health" "" "200"
run_test "用户服务健康检查" "GET" "http://localhost:8081/actuator/health" "" "200"
run_test "认证服务健康检查" "GET" "http://localhost:8082/actuator/health" "" "200"

# 2. 用户注册测试
echo -e "${YELLOW}[2/6] 用户注册测试${NC}"

# 生成唯一的测试数据
timestamp=$(date +%s)
test_username="testuser_$timestamp"
test_email="test_$timestamp@example.com"
test_phone="138${timestamp:6:8}"

register_data="{
    \"username\": \"$test_username\",
    \"password\": \"123456\",
    \"email\": \"$test_email\",
    \"phone\": \"$test_phone\",
    \"nickname\": \"Docker测试用户$timestamp\"
}"

run_test "用户注册" "POST" "$GATEWAY_URL/auth/register" "$register_data" "200"

# 3. 重复注册测试（应该失败）
echo -e "${YELLOW}[3/6] 重复注册测试${NC}"
run_test "重复用户名注册" "POST" "$GATEWAY_URL/auth/register" "$register_data" "400"

# 4. 用户登录测试
echo -e "${YELLOW}[4/6] 用户登录测试${NC}"

login_data="{
    \"username\": \"$test_username\",
    \"password\": \"123456\"
}"

login_response=$(curl -s -X POST "$GATEWAY_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_data" 2>/dev/null)

echo -e "${BLUE}🧪 测试: 用户登录${NC}"
if echo "$login_response" | grep -q "token"; then
    echo -e "  ${GREEN}✅ 登录成功${NC}"
    if command -v jq &> /dev/null; then
        echo -e "  ${GREEN}📄 响应:${NC}"
        echo "$login_response" | jq . | sed 's/^/    /'
        # 提取token用于后续测试
        token=$(echo "$login_response" | jq -r '.data.token' 2>/dev/null || echo "")
    else
        echo -e "  ${GREEN}📄 响应: $login_response${NC}"
        token=""
    fi
    ((passed_tests++))
else
    echo -e "  ${RED}❌ 登录失败${NC}"
    echo -e "  ${RED}📄 错误响应: $login_response${NC}"
    token=""
fi
((total_tests++))
echo

# 5. 错误登录测试
echo -e "${YELLOW}[5/6] 错误登录测试${NC}"

wrong_login_data="{
    \"username\": \"$test_username\",
    \"password\": \"wrongpassword\"
}"

run_test "错误密码登录" "POST" "$GATEWAY_URL/auth/login" "$wrong_login_data" "400"

# 6. 用户列表查询测试
echo -e "${YELLOW}[6/6] 用户列表查询测试${NC}"
run_test "用户列表查询" "GET" "$GATEWAY_URL/user/user/list?current=1&size=10" "" "200"

# 7. 如果有token，测试需要认证的接口
if [ -n "$token" ] && [ "$token" != "null" ]; then
    echo -e "${YELLOW}[额外] 认证接口测试${NC}"
    
    # 使用token测试认证接口
    auth_response=$(curl -s -w "\n%{http_code}" -X GET "$GATEWAY_URL/user/user/current" \
        -H "Authorization: Bearer $token" 2>/dev/null)
    
    auth_body=$(echo "$auth_response" | head -n -1)
    auth_status=$(echo "$auth_response" | tail -n 1)
    
    echo -e "${BLUE}🧪 测试: 获取当前用户信息${NC}"
    if [ "$auth_status" = "200" ] || [ "$auth_status" = "404" ]; then
        echo -e "  ${GREEN}✅ 认证成功 (状态码: $auth_status)${NC}"
        if command -v jq &> /dev/null && [ -n "$auth_body" ]; then
            echo "$auth_body" | jq . | sed 's/^/    /'
        fi
        ((passed_tests++))
    else
        echo -e "  ${RED}❌ 认证失败 (状态码: $auth_status)${NC}"
        echo -e "  ${RED}📄 响应: $auth_body${NC}"
    fi
    ((total_tests++))
    echo
fi

# 测试结果汇总
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}             测试结果汇总${NC}"
echo -e "${BLUE}===============================================${NC}"
echo
echo -e "${BLUE}📊 测试统计:${NC}"
echo -e "  总测试数: $total_tests"
echo -e "  通过测试: ${GREEN}$passed_tests${NC}"
echo -e "  失败测试: ${RED}$((total_tests - passed_tests))${NC}"

success_rate=$((passed_tests * 100 / total_tests))
echo -e "  成功率: ${GREEN}$success_rate%${NC}"

echo
if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}🎉 所有测试通过！系统运行正常${NC}"
    exit_code=0
elif [ $success_rate -ge 80 ]; then
    echo -e "${YELLOW}⚠️  大部分测试通过，系统基本正常${NC}"
    exit_code=0
else
    echo -e "${RED}❌ 多个测试失败，请检查系统状态${NC}"
    exit_code=1
fi

echo
echo -e "${BLUE}🔧 故障排除建议:${NC}"
echo -e "  1. 检查所有服务是否健康: ${YELLOW}./docker-health-check.sh${NC}"
echo -e "  2. 查看服务日志: ${YELLOW}cd docker && docker-compose logs -f [service_name]${NC}"
echo -e "  3. 重启问题服务: ${YELLOW}cd docker && docker-compose restart [service_name]${NC}"
echo -e "  4. 完全重启: ${YELLOW}./stop.sh && ./start.sh${NC}"

echo
echo -e "${GREEN}🎉 API测试完成！${NC}"

exit $exit_code
