@echo off
chcp 65001
echo ========================================
echo NiceVideo 微服务启动脚本 (仅启动服务)
echo ========================================

echo.
echo [提示] 此脚本仅启动服务，不进行构建
echo [提示] 请确保已经运行过 start-windows.bat 或手动构建项目
echo.

echo 检查JAR文件是否存在...
if not exist "eureka-server\target\eureka-server-1.0.0.jar" (
    echo [错误] 未找到 eureka-server JAR文件
    echo [提示] 请先运行 start-windows.bat 构建项目
    pause
    exit /b 1
)

if not exist "config-service\target\config-service-1.0.0.jar" (
    echo [错误] 未找到 config-service JAR文件
    echo [提示] 请先运行 start-windows.bat 构建项目
    pause
    exit /b 1
)

if not exist "user-service\target\user-service-1.0.0.jar" (
    echo [错误] 未找到 user-service JAR文件
    echo [提示] 请先运行 start-windows.bat 构建项目
    pause
    exit /b 1
)

if not exist "auth-service\target\auth-service-1.0.0.jar" (
    echo [错误] 未找到 auth-service JAR文件
    echo [提示] 请先运行 start-windows.bat 构建项目
    pause
    exit /b 1
)

if not exist "gateway-service\target\gateway-service-1.0.0.jar" (
    echo [错误] 未找到 gateway-service JAR文件
    echo [提示] 请先运行 start-windows.bat 构建项目
    pause
    exit /b 1
)

echo [成功] 所有JAR文件检查通过
echo.

echo 启动各个服务...

echo.
echo 1. 启动Eureka服务注册中心 (端口: 8761)
start "Eureka Server" cmd /k "cd /d %CD%\eureka-server && java -jar target/eureka-server-1.0.0.jar"

echo [等待] Eureka服务启动中...
timeout /t 10 /nobreak >nul

echo.
echo 2. 启动配置中心服务 (端口: 8888)
start "Config Service" cmd /k "cd /d %CD%\config-service && java -jar target/config-service-1.0.0.jar"

echo [等待] 配置中心启动中...
timeout /t 10 /nobreak >nul

echo.
echo 3. 启动用户服务 (端口: 8081)
start "User Service" cmd /k "cd /d %CD%\user-service && java -jar target/user-service-1.0.0.jar"

echo [等待] 用户服务启动中...
timeout /t 10 /nobreak >nul

echo.
echo 4. 启动认证服务 (端口: 8082)
start "Auth Service" cmd /k "cd /d %CD%\auth-service && java -jar target/auth-service-1.0.0.jar"

echo [等待] 认证服务启动中...
timeout /t 10 /nobreak >nul

echo.
echo 5. 启动API网关服务 (端口: 8080)
start "Gateway Service" cmd /k "cd /d %CD%\gateway-service && java -jar target/gateway-service-1.0.0.jar"

echo.
echo ========================================
echo 服务启动完成！
echo ========================================
echo.
echo 服务访问地址：
echo   Eureka服务注册中心: http://localhost:8761
echo   配置中心: http://localhost:8888
echo   API网关: http://localhost:8080
echo   用户服务: http://localhost:8081
echo   认证服务: http://localhost:8082
echo.
echo [提示] 按任意键退出...
pause >nul



