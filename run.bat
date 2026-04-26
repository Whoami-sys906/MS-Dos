@echo off
REM Windows batch file to run Simple MS-DOS in QEMU

echo Starting Simple MS-DOS in QEMU...
echo.

REM Check if QEMU is installed
qemu-system-i386 --version >nul 2>&1
if errorlevel 1 (
    echo Error: QEMU is not installed or not in PATH
    echo Please install QEMU for Windows from https://qemu.weilnetz.de/
    pause
    exit /b 1
)

REM Check if disk image exists
if not exist "bin\msdos.img" (
    echo Error: Disk image not found
    echo Please run 'make' first to build the OS
    pause
    exit /b 1
)

REM Run QEMU
qemu-system-i386 -fda bin\msdos.img

pause
