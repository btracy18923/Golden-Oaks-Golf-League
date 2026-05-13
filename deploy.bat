@echo off
cd /d "%~dp0"

echo.
echo ============================================================
echo   Golden Oaks Golf League - Deploy to Netlify
echo ============================================================
echo.
echo   This deploys BOTH the website AND the email function.
echo.
echo   IMPORTANT: Do NOT use Netlify drag-and-drop to deploy.
echo   Drag-and-drop only uploads the website files and will
echo   break the Email Blast feature (/.netlify/functions/send-email).
echo   Always use this script instead.
echo.
echo   Site: https://goldenoaks.golf
echo   Site ID: a5524473-6fac-4c82-af9a-26095788d721
echo.
echo ============================================================
echo.

netlify deploy --prod --site a5524473-6fac-4c82-af9a-26095788d721

echo.
pause