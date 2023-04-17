@echo off
cls
echo Running PowerShell script : # NAVCreateDevEnv_DockerContainer.ps1
powershell.exe -NoProfile -Executionpolicy Bypass -Command "&{start-process powershell -ArgumentList '-NoProfile -Executionpolicy Bypass -File ""%~dp0NAVCreateDevEnv-DockerContainer.ps1""' -verb RunAs}"
