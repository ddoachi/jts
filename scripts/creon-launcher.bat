@echo off
REM Generated from spec: E01-F02-T04 (Environment Configuration and Secrets Management)
REM Spec ID: 021bbc7e
REM ================================================================
REM Creon Launcher Script - Wrapper for auto-login
REM ================================================================

echo [%date% %time%] Starting Creon launcher... >> %CREON_LOG_PATH%\creon-launcher.log

REM Check if auto-login script exists
if not exist "%CREON_SCRIPT_PATH%\auto-login.bat" (
    echo ERROR: auto-login.bat not found at %CREON_SCRIPT_PATH%
    echo Please place your Creon auto-login script in the secure directory
    exit /b 1
)

REM Execute the auto-login script
echo [%date% %time%] Executing auto-login script... >> %CREON_LOG_PATH%\creon-launcher.log
call "%CREON_SCRIPT_PATH%\auto-login.bat"

if %errorlevel% neq 0 (
    echo [%date% %time%] Auto-login failed with error code %errorlevel% >> %CREON_LOG_PATH%\creon-launcher.log
    exit /b %errorlevel%
)

echo [%date% %time%] Creon launcher completed successfully >> %CREON_LOG_PATH%\creon-launcher.log
exit /b 0