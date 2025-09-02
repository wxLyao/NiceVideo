@echo off
chcp 65001
echo ===============================================
echo       停止NiceVideo微服务项目（Docker模式）
echo ===============================================

echo.
echo [1/3] 停止所有服务容器...
cd docker
docker-compose down

echo.
echo [2/3] 清理容器和网络...
docker-compose down -v --remove-orphans

echo.
echo [3/3] 显示当前容器状态...
docker ps -a --filter "name=nicevideo"

echo.
echo ===============================================
echo             服务已停止！
echo ===============================================
echo.
echo 💡 如需完全清理（包括镜像和数据卷）：
echo    docker-compose down -v --rmi all
echo    docker volume prune -f
echo.

pause
