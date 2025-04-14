@echo off
setlocal

set "currentDir=%~dp0"
"%currentDir%Nebel.exe" /SU auto
"%currentDir%Nebel.exe" /BS %RANDOM%-%RANDOM%-%RANDOM%
"%currentDir%Nebel.exe" /CS %RANDOM%-%RANDOM%-%RANDOM%

exit
