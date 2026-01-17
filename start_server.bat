@echo off
cd /d "%~dp0netlify_website"
echo Starting Golf League web server on http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo.
python -m http.server 8000
pause
