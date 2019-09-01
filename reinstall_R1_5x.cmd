REM SPDX-License-Identifier: (GPL-2.0+ OR MIT)

REM ****************************************************
REM *                                                  *
REM *      Resolution One (v5.x) Reinstall Script      *
REM *                                                  *
REM ****************************************************
REM *                                                  *
REM *      !!! THIS IS NOT GUARANTEED TO WORK !!!      *
REM *                                                  *
REM ****************************************************

@ECHO OFF
SETLOCAL enableextensions

reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{0ADB4ED4-61E5-4325-A832-20753FBF466A} /v DisplayVersion | findstr 5.5 && set version="5.5" && GOTO CheckOS
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{87E1E167-EC21-462C-8F96-B1861ECDB161} /v DisplayVersion | findstr 5.8 && set version="5.8" || GOTO END_BATCH && GOTO CheckOS

echo %version% | findstr 5.5 && echo Uninstalling v5.5 && msiexec /x {0ADB4ED4-61E5-4325-A832-20753FBF466A} NUKE=1 /quiet /norestart
echo %version% | findstr 5.8 && echo Uninstalling v5.8 && msiexec /x {87E1E167-EC21-462C-8F96-B1861ECDB161} NUKE=1 /quiet /norestart

echo Installing new version!

IF EXIST "C:\Program Files\AccessData\Agent\AgentCore.exe" (GOTO END_BATCH)
md c:\tempcirt\

:CheckOS
IF EXIST "%PROGRAMFILES(X86)%" (GOTO 64BIT)

:32BIT
xcopy "\\<UNC Path of Share>\*" "c:\tempcirt\*" /F /C /R /Y /Z
msiexec /i "C:\tempcirt\AccessData Agent.msi" CER="C:\tempcirt\<Public Certificate>.crt" FOLDER_STORAGE=1 MAMA=<IP_Address>:54555 allusers=2
GOTO END_BATCH

:64BIT
xcopy "\\<UNC Path of Share>\*" "c:\tempcirt\*" /F /C /R /Y /Z
msiexec /i "C:\tempcirt\AccessData Agent (64-bit).msi" CER="C:\tempcirt\<Public Certificate>.crt" FOLDER_STORAGE=1 MAMA=<IP_Address>:54555 allusers=2
GOTO END_BATCH

:END_BATCH
