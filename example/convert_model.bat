@echo off
echo ========================================
echo PyTorch 到 TFLite 模型转换工具
echo ========================================
echo.

echo 检查 Python 环境...
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 错误：未找到 Python，请确保 Python 已安装并添加到 PATH
    pause
    exit /b 1
)

echo ✅ Python 已就绪

echo.
echo 正在安装必要的依赖包...
pip install -r requirements.txt

echo.
echo 开始转换模型...
echo 这可能需要几分钟时间，请耐心等待...
echo.

python convert_simple.py

echo.
echo ========================================
echo 转换完成
echo ========================================
echo.

if %ERRORLEVEL% EQU 0 (
    echo ✅ 转换成功！
    echo.
    echo 后续步骤：
    echo 1. 运行: flutter clean && flutter pub get
    echo 2. 运行: flutter build apk --debug
    echo 3. 使用新编译的 APK 进行测试
) else (
    echo ❌ 转换失败！
    echo.
    echo 请检查错误信息并确保：
    echo 1. 模型文件存在
    echo 2. Python 包已正确安装
    echo 3. 有足够的磁盘空间
)

pause