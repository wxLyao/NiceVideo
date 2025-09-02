@echo off
chcp 65001
echo ========================================
echo NiceVideo 完整构建脚本
echo ========================================

echo.
echo [提示] 开始完整构建项目...
echo [提示] 这可能需要几分钟时间，请耐心等待...
echo [提示] Maven会自动处理模块依赖关系
echo.

call mvn clean install -DskipTests

if errorlevel 1 (
    echo.
    echo [错误] 项目构建失败！
    echo [提示] 请检查错误信息并修复问题
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo [成功] 项目构建完成！
    echo [提示] 现在可以运行 start-simple.bat 启动服务
    echo.
    pause
)



