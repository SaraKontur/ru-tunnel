@echo off

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run as Administrator.
    pause
    exit /b 1
)

for /f "skip=4 tokens=3" %%i in ('route print 0.0.0.0') do (
    set GATEWAY=%%i
    goto :found
)

:found
echo.
echo Detected gateway: %GATEWAY%
echo If this is wrong, type the correct one. Otherwise press Enter.
echo.
set /p CONFIRM="Gateway [%GATEWAY%]: "
if not "%CONFIRM%"=="" set GATEWAY=%CONFIRM%

echo.
choice /C YN /N /M "Install routes? [Y/N]: "
if errorlevel 2 exit /b 0

echo.
echo Downloading...
echo.

powershell -ExecutionPolicy Bypass -Command "$gateway = '%GATEWAY%'; $ranges = (Invoke-WebRequest -Uri 'https://www.ipdeny.com/ipblocks/data/countries/ru.zone' -UseBasicParsing).Content -split \"`n\" | Where-Object { $_ -match '\d' }; $total = $ranges.Count; $i = 0; foreach ($range in $ranges) { $i++; $parts = $range.Trim() -split '/'; if ($parts.Count -eq 2) { $ip = $parts[0]; $prefix = [int]$parts[1]; $mask = ([System.Net.IPAddress]([uint32]::MaxValue -shl (32 - $prefix) -band [uint32]::MaxValue)).ToString(); route delete $ip mask $mask 2>&1 | Out-Null; route add $ip mask $mask $gateway -p 2>&1 | Out-Null; Write-Host \"`rProgress: $i / $total\" -NoNewline } }; Write-Host ''"

echo.
echo Done.
pause
