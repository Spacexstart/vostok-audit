@echo off
REM Hugo site helper launcher. Double-click to open menu.
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\menu.ps1"
if errorlevel 1 pause
