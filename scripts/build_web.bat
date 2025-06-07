@echo off
echo Building GigaEats Web Application...
echo.

echo Step 1: Cleaning previous builds...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building for web (production)...
flutter build web --release

echo.
echo Step 4: Build completed!
echo Web files are available in: build\web\
echo.
echo To serve locally, run:
echo   cd build\web
echo   python -m http.server 8080
echo   OR
echo   npx serve -s . -l 8080
echo.
echo To deploy, upload the contents of build\web\ to your web server.
echo.
pause
