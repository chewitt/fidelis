REM SPDX-License-Identifier: (GPL-2.0+ OR MIT)

REM **************************************************
REM *                                                *
REM *      Fidelis Endpoint GPO Install Script       *
REM *                                                *
REM **************************************************
REM *                                                *
REM *     !!! THIS IS NOT GUARANTEED TO WORK !!!     *
REM *                                                *
REM **************************************************

@ECHO OFF

IF EXIST "C:\Program Files\Fidelis\Endpoint\Platform\Endpoint.exe" GOTO END

REM -- Disable UAC
C:\Windows\System32\cmd.exe /k %WINDIR%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

REM -- Copy Files (requires a restricted credential)
NET USE f: \\server\share PASSWORD /user:DOMAIN\USERNAME
TIMEOUT /t 2 /nobreak
XCOPY /y /f "F:\Fidelis Endpoint Platform.exe" "%TEMP%"
XCOPY /y /f "F:\AgentSetup.txt" "%TEMP%"

REM -- Download Files (requires anonymous access to a webserver)
REM C:\Windows\System32\cmd.exe /k %WINDIR%\System32\bitsadmin.exe /transfer "Fidelis" "http://server.local/Fidelis%20Endpoint%20Platform.exe" "%TEMP%\Fidelis Endpoint Platform.exe"
REM C:\Windows\System32\cmd.exe /k %WINDIR%\System32\bitsadmin.exe /transfer "Fidelis" "http://server.local/AgentSetup.txt" "%TEMP%\AgentSetup.txt"

REM -- Install Agent
IF EXIST "%TEMP%\Fidelis Endpoint Platform.exe" (
  IF EXIST "%TEMP%\AgentSetup.txt" (
    C:\Windows\System32\cmd.exe /k "%TEMP%\Fidelis Endpoint Platform.exe" /install /quiet /norestart config_path="%TEMP%\AgentSetup.txt"
    ) ELSE (
    EXIT
  )
  ) ELSE (
  EXIT
)

REM -- Cleanup
DEL "%TEMP%\Fidelis Endpoint Platform.exe" /f /q
DEL "%TEMP%\AgentSetup.txt" /f /q
NET USE f: /delete

REM -- Enable UAC
C:\Windows\System32\cmd.exe /k %WINDIR%\System32\reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f

:END
