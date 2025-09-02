# NiceVideo Docker环境设置脚本
# PowerShell版本

param(
    [switch]$WSL = $false,
    [switch]$SkipDockerCheck = $false
)

Write-Host "===============================================" -ForegroundColor Blue
Write-Host "      NiceVideo Docker环境设置" -ForegroundColor Blue
Write-Host "===============================================" -ForegroundColor Blue
Write-Host

# 检查PowerShell版本
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "❌ 需要PowerShell 5.0或更高版本" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PowerShell版本检查通过: $($PSVersionTable.PSVersion)" -ForegroundColor Green

if (-not $SkipDockerCheck) {
    Write-Host
    Write-Host "[1/4] 检查Docker环境..." -ForegroundColor Yellow
    
    # 检查Docker是否安装
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker已安装: $dockerVersion" -ForegroundColor Green
        } else {
            throw "Docker未安装"
        }
    } catch {
        Write-Host "❌ Docker未安装或未启动" -ForegroundColor Red
        Write-Host "   请安装Docker Desktop并确保其正在运行" -ForegroundColor Red
        Write-Host "   下载地址: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        exit 1
    }
    
    # 检查Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Compose已安装: $composeVersion" -ForegroundColor Green
        } else {
            throw "Docker Compose未安装"
        }
    } catch {
        Write-Host "❌ Docker Compose未安装" -ForegroundColor Red
        exit 1
    }
    
    # 检查Docker是否运行
    try {
        docker info | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker服务运行正常" -ForegroundColor Green
        } else {
            throw "Docker服务未运行"
        }
    } catch {
        Write-Host "❌ Docker服务未运行，请启动Docker Desktop" -ForegroundColor Red
        exit 1
    }
}

Write-Host
Write-Host "[2/4] 检查WSL环境..." -ForegroundColor Yellow

if ($WSL) {
    # 检查WSL
    try {
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ WSL已安装" -ForegroundColor Green
            Write-Host "💡 建议使用WSL环境运行项目以获得最佳性能" -ForegroundColor Cyan
            Write-Host "   运行以下命令进入WSL并初始化环境:" -ForegroundColor Cyan
            Write-Host "   wsl" -ForegroundColor Yellow
            Write-Host "   cd /mnt/c/Users/$env:USERNAME/Documents/NiceVideo" -ForegroundColor Yellow
            Write-Host "   ./wsl-setup.sh" -ForegroundColor Yellow
        } else {
            Write-Host "⚠️  WSL未安装，将使用Windows原生Docker" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  WSL未安装，将使用Windows原生Docker" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  使用Windows原生Docker模式" -ForegroundColor Cyan
}

Write-Host
Write-Host "[3/4] 检查Java和Maven..." -ForegroundColor Yellow

# 检查Java
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    if ($javaVersion) {
        Write-Host "✅ Java已安装: $($javaVersion.Line)" -ForegroundColor Green
    } else {
        throw "Java未安装"
    }
} catch {
    Write-Host "⚠️  Java未安装，将在Docker容器中构建" -ForegroundColor Yellow
    Write-Host "   如需本地开发，请安装JDK 11+" -ForegroundColor Yellow
}

# 检查Maven
try {
    $mavenVersion = mvn --version 2>&1 | Select-String "Apache Maven"
    if ($mavenVersion) {
        Write-Host "✅ Maven已安装: $($mavenVersion.Line)" -ForegroundColor Green
    } else {
        throw "Maven未安装"
    }
} catch {
    Write-Host "⚠️  Maven未安装，将在Docker容器中构建" -ForegroundColor Yellow
    Write-Host "   如需本地开发，请安装Maven 3.6+" -ForegroundColor Yellow
}

Write-Host
Write-Host "[4/4] 创建启动脚本..." -ForegroundColor Yellow

# 创建快速启动脚本
$quickStartScript = @"
@echo off
chcp 65001 >nul
echo 🚀 快速启动NiceVideo项目...
echo.

echo [1/2] 构建项目...
call mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ❌ Maven构建失败，尝试Docker构建...
    cd docker
    docker-compose up -d --build
) else (
    echo ✅ Maven构建成功
    echo [2/2] 启动Docker容器...
    cd docker
    docker-compose up -d --build
)

echo.
echo ✅ 启动完成！
echo 🌐 访问地址: http://localhost:8080
echo 📊 Eureka: http://localhost:8761
echo.
pause
"@

$quickStartScript | Out-File -FilePath "quick-start.bat" -Encoding Default

Write-Host "✅ 创建了快速启动脚本: quick-start.bat" -ForegroundColor Green

Write-Host
Write-Host "===============================================" -ForegroundColor Blue
Write-Host "           环境设置完成！" -ForegroundColor Blue
Write-Host "===============================================" -ForegroundColor Blue
Write-Host

Write-Host "🚀 启动选项:" -ForegroundColor Blue
Write-Host "   Windows原生: " -NoNewline -ForegroundColor Cyan
Write-Host "docker-start-windows.bat" -ForegroundColor Yellow
Write-Host "   快速启动:   " -NoNewline -ForegroundColor Cyan
Write-Host "quick-start.bat" -ForegroundColor Yellow

if ($WSL) {
    Write-Host "   WSL环境:    " -NoNewline -ForegroundColor Cyan
    Write-Host "进入WSL后运行 ./docker-start-wsl.sh" -ForegroundColor Yellow
}

Write-Host
Write-Host "🔧 管理命令:" -ForegroundColor Blue
Write-Host "   停止服务:   " -NoNewline -ForegroundColor Cyan
Write-Host "docker-stop-windows.bat" -ForegroundColor Yellow
Write-Host "   查看状态:   " -NoNewline -ForegroundColor Cyan
Write-Host "cd docker && docker-compose ps" -ForegroundColor Yellow
Write-Host "   查看日志:   " -NoNewline -ForegroundColor Cyan
Write-Host "cd docker && docker-compose logs -f" -ForegroundColor Yellow

Write-Host
Write-Host "📚 更多信息:" -ForegroundColor Blue
Write-Host "   Docker指南: " -NoNewline -ForegroundColor Cyan
Write-Host "README-Docker.md" -ForegroundColor Yellow
Write-Host "   API文档:    " -NoNewline -ForegroundColor Cyan
Write-Host "API.md" -ForegroundColor Yellow

Write-Host
Write-Host "🎉 准备就绪！选择一个启动脚本开始使用吧！" -ForegroundColor Green
