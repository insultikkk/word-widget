@echo off
start "Word Widget" /min powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0WordWidget.ps1"