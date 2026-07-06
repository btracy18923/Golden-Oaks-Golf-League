@echo off
cd /d "%~dp0"

echo.
echo ============================================================
echo   Golden Oaks Golf League - Build and Release APK
echo ============================================================
echo.
echo   Step 1: Builds the release APK
echo   Step 2: Creates a GitHub Release and uploads the APK
echo.
echo   The version is read automatically from app_config.dart.
echo   Make sure you have updated the versionDate there first.
echo.
echo ============================================================
echo.

:: Refresh PATH to ensure gh CLI is available
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "MACHINE_PATH=%%b"
set "PATH=%MACHINE_PATH%;%PATH%"

:: Read version from app_config.dart
for /f "tokens=2 delims='" %%a in ('findstr "versionDate" lib\config\app_config.dart') do set VERSION=%%a

echo   Version: %VERSION%
echo.

:: Step 1: Build the release APK
echo Building release APK...
echo.
flutter build apk --release
if errorlevel 1 (
    echo.
    echo ERROR: Flutter build failed. Release not created.
    pause
    exit /b 1
)

echo.
echo APK built successfully.
echo.

:: Step 2: Create GitHub release and upload APK
echo Creating GitHub Release %VERSION% and uploading APK...
echo.
gh release create %VERSION% "build/app/outputs/flutter-apk/app-release.apk" --title "Golden Oaks Golf League %VERSION%" --notes "Release %VERSION%"
if errorlevel 1 (
    echo.
    echo ERROR: GitHub release failed. Check that version %VERSION% does not already exist.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS!
echo   Version %VERSION% is now available at:
echo   https://github.com/btracy18923/Golden-Oaks-Golf-League/releases/latest
echo ============================================================
echo.
pause
