@echo off
echo Starting GigaEats Web Server...
echo.

if not exist "build\web\index.html" (
    echo Error: Web build not found!
    echo Please run build_web.bat first.
    echo.
    pause
    exit /b 1
)

echo Serving GigaEats at http://localhost:8080
echo Press Ctrl+C to stop the server
echo.

cd build\web
python -m http.server 8080
