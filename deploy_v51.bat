@echo off
echo ===================================================
echo   DEPLOYING MEGA PANEL AI (v51 FIX)
echo ===================================================
echo.

echo 1. Cleaning project...
call flutter clean
if %errorlevel% neq 0 (
    echo Error cleaning project.
    pause
    exit /b %errorlevel%
)

echo 2. Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Error getting dependencies.
    pause
    exit /b %errorlevel%
)

echo 3. Building APK (Release)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo BUILD FAILED!
    pause
    exit /b %errorlevel%
)

echo 4. Installing on connected device...
call flutter install
if %errorlevel% neq 0 (
    echo INSTALL FAILED! Is the device connected and USB debugging enabled?
    echo You can install manually: build\app\outputs\flutter-apk\app-release.apk
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===================================================
pause
