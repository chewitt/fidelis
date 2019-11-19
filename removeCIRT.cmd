@echo off
setlocal enableextensions

echo.
echo ------------------------------
echo 1. Stopping Agent Service
echo ------------------------------
echo.

if /i "%processor_architecture%"=="AMD64" GOTO Service_x64
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" GOTO Service_x64
if /i "%processor_architecture%"=="x86" GOTO Service_x86

:Service_x64
net stop AgentService.x64
timeout 5
GOTO Service_JUMP

:Service_x86
net stop AgentService
timeout 5

:Service_JUMP

echo.
echo -------------------------
echo 2. Uninstalling Drivers
echo -------------------------
echo.

if /i "%processor_architecture%"=="AMD64" GOTO Driver_x64
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" GOTO Driver_x64
if /i "%processor_architecture%"=="x86" GOTO Driver_x86

:Driver_x64
echo .
echo Uninstalling adfilemon.inf driver
C:\PROGRA~1\DIFX\B60D1297D6D5E54C\DPinst.exe /u C:\Windows\system32\DRVSTORE\adfilemon_F1E9BD844EFBBF3A7794BE24A64A7D3D046E386E\adfilemon.inf /q
timeout 5
echo.
echo Uninstalling adnetmon.inf driver
C:\PROGRA~1\DIFX\B60D1297D6D5E54C\DPinst.exe /u C:\Windows\system32\DRVSTORE\adnetmon_30126AC155B4E4221BA815D747886FF87A23DB6D\adnetmon.inf /q
timeout 5
GOTO Driver_JUMP

:Driver_x86
echo.
echo Uninstalling adfilemon.inf driver
C:\PROGRA~1\DIFX\507DAFEF8EE1D9B8\DPinst.exe /u C:\Windows\system32\DRVSTORE\adnetmon_56D10A8159AE2F57DF8F29F61D6A982A9C19C953\adnetmon.inf /q
timeout 5
echo.
echo Uninstalling adnetmon.inf driver
C:\PROGRA~1\DIFX\507DAFEF8EE1D9B8\DPinst.exe /u C:\Windows\system32\DRVSTORE\adfilemon_F412CD296F1C59FBA2FC7400E6DB5BC66B02680D\adfilemon.inf /q
timeout 5

:Driver_JUMP
echo.
echo ------------------------------
echo 3. Checking Agent Version
echo ------------------------------
echo.

reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{0ADB4ED4-61E5-4325-A832-20753FBF466A} /v DisplayVersion
IF %ERRORLEVEL%==0 echo Uninstalling Version 5.5.x ... && GOTO UNINSTALL_Version_55

reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{87E1E167-EC21-462C-8F96-B1861ECDB161} /v DisplayVersion
IF %ERRORLEVEL%==0 echo Uninstalling Version 5.8.x ... && GOTO UNINSTALL_Version_58

:UNINSTALL_Version_55
msiexec /x {0ADB4ED4-61E5-4325-A832-20753FBF466A} NUKE=1 /quiet /norestart
echo.
echo ------------------------------
echo 4. Uninstallation Compelete
echo ------------------------------
echo.
GOTO Uninstall_JUMP

:UNINSTALL_Version_58
msiexec /x {87E1E167-EC21-462C-8F96-B1861ECDB161} NUKE=1 /quiet /norestart
echo.
echo ------------------------------
echo 4. Uninstallation Compelete
echo ------------------------------
echo.

:Uninstall_JUMP

:END_BATCH
echo.
echo -------------------------
echo uninstallation Complete!
echo -------------------------
echo.
