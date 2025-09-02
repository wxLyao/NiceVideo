@echo off
chcp 65001
echo ===============================================
echo       启动NiceVideo微服务项目（Docker模式）
echo ===============================================

echo.
echo [1/5] 检查Docker环境...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：Docker未安装或未启动
    echo    请确保Docker Desktop已安装并正在运行
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：Docker Compose未安装
    echo    请安装Docker Compose
    pause
    exit /b 1
)

echo ✅ Docker环境检查通过

echo.
echo [2/5] 停止并清理现有容器...
cd docker
docker-compose down -v 2>nul
docker system prune -f >nul 2>&1

echo.
echo [3/5] 构建Maven项目...
cd ..
call mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ❌ 错误：Maven构建失败
    pause
    exit /b 1
)
echo ✅ Maven构建完成

echo.
echo [4/5] 启动Docker容器...
cd docker
docker-compose up -d --build
if errorlevel 1 (
    echo ❌ 错误：Docker容器启动失败
    pause
    exit /b 1
)

echo.
echo [5/5] 等待服务启动...
timeout /t 10 /nobreak >nul

echo.
echo 📊 服务状态检查：
docker-compose ps

echo.
echo ===============================================
echo             服务启动完成！
echo ===============================================
echo.
echo 🌐 服务访问地址：
echo    📍 Eureka服务注册中心: http://localhost:8761
echo    ⚙️  配置中心:         http://localhost:8888
echo    🚪 API网关:          http://localhost:8080
echo    👤 用户服务:         http://localhost:8081
echo    🔐 认证服务:         http://localhost:8082
echo.
echo 🧪 API测试示例：
echo    注册用户: POST http://localhost:8080/api/auth/register
echo    用户登录: POST http://localhost:8080/api/auth/login
echo    用户列表: GET  http://localhost:8080/api/user/user/list
echo.
echo 📝 查看日志: docker-compose logs -f [service_name]
echo 🛑 停止服务: docker-compose down
echo.

pause
