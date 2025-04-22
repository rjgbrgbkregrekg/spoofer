@echo off
title Nebel Free Mac Spoofer
setlocal EnableDelayedExpansion
mode con:cols=66 lines=25

:: Check for administrator privileges
fltmc >nul 2>&1 || (
    echo( && echo   [33m# Administrator privileges are required. && echo([0m
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo   [33m# Right-click on the script and select "Run as administrator".[0m
        >nul pause && exit 1
    )
    exit 0
)

:: Variables
set "reg_path=HKLM\SYSTEM\ControlSet001\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

:: Automatically spoof MAC address for all valid NICs
cls && echo( && echo   [35mStarting MAC address spoofing...[0m && echo(
for /f "skip=2 tokens=2 delims=," %%A in ('wmic nic get netconnectionid /format:csv') do (
    for /f "delims=" %%B in ("%%~A") do (
        set "NetworkAdapter=%%B"
        echo   [31m# Spoofing MAC for:%%B[0m
        call :SPOOF
    )
)

echo( && echo   [32m# MAC Address spoofing completed for all NICs.[0mexit /b


:SPOOF
cls && echo( && call :MAC_Recieve && call :generate_mac && call :NIC_Index
echo   [31m# Selected NIC :[0m !NetworkAdapter! && echo(
echo   [31m# Current MAC  :[0m !MAC! && echo(
echo   [31m# Spoofed MAC  :[0m !mac_address!
>nul 2>&1 (
    netsh interface set interface "!NetworkAdapter!" admin=disable
    reg delete "!reg_path!\!Index!" /v "OriginalNetworkAddress" /f
    reg add "!reg_path!\!Index!" /v "NetworkAddress" /t REG_SZ /d "!mac_address!" /f
    netsh interface set interface "!NetworkAdapter!" admin=enable
)

:: Restart the adapter (additional command to make sure the network adapter restarts cleanly)
netsh interface set interface "!NetworkAdapter!" admin=disable
timeout /t 2 >nul
netsh interface set interface "!NetworkAdapter!" admin=enable

exit /b


:: Generating Random MAC Address
:: The second character of the first octet of the MAC Address needs to contain A, E, 2, or 6 to properly function for certain wireless NIC's. Example: xA:xx:xx:xx:xx
:generate_mac
set #hex_chars=0123456789ABCDEF`AE26
if defined mac_address (
    set mac_address= 
)
for /l %%A in (1,1,11) do (
    set /a "random_index=!random! %% 16"
    for %%B in (!random_index!) do (
        set mac_address=!mac_address!!#hex_chars:~%%B,1!
    )
)
set /a "random_index=!random! %% 4 + 17"
set mac_address=!mac_address:~0,1!!#hex_chars:~%random_index%,1!!mac_address:~1!
exit /b


:: Retrieving Current MAC Address
:MAC_Recieve
call :NIC_Index
for /f "tokens=3" %%A in ('reg query "!reg_path!\!Index!" ^| find "NetworkAddress"') do set "MAC=%%A"

:: An unmodified MAC address will not be listed in the registry, so get the default MAC address with WMIC.
if "!MAC!"=="" (
    set /a raw_index=1!index!-10000
    for /f "delims=" %%A in ('"wmic nic where Index="!raw_index!" get MacAddress /format:value"') do (
        for /f "tokens=2 delims==" %%B in ("%%~A") do set "MAC=%%B"
    )
)
exit /b


:: Retrieving current Caption/Index
:NIC_Index
for /f "delims=" %%A in ('"wmic nic where NetConnectionId="!NetworkAdapter!" get Caption /format:value"') do (
    for /f "tokens=2 delims=[]" %%A in ("%%~A") do (
        set "Index=%%A"
        set "Index=!Index:~-4!"
    )
)
exit /b 0
