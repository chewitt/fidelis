REM SPDX-License-Identifier: (GPL-2.0+ OR MIT)

REM **************************************************
REM *                                                *
REM *      Fidelis Endpoint GPO Install Script       *
REM *                                                *
REM **************************************************
REM *                                                *
REM *  This script requires installer files to be    *
REM *  stored in a shared folder mapped to the F:    *
REM *  drive letter on the Endpoint. It is best to   *
REM *  do the mapping via GPO, and to execute the    *
REM *  script from the local drive of the Endpoint   *
REM *                                                *
REM **************************************************

@ECHO OFF

IF EXIST "C:\Program Files\Fidelis\Endpoint\Platform\Endpoint.exe" GOTO END

REM -- Download Files (requires anonymous access to a webserver)
REM C:\Windows\System32\cmd.exe /k %WINDIR%\System32\bitsadmin.exe /transfer "Fidelis" "http://server.local/Fidelis%20Endpoint%20Platform.exe" "%TEMP%\Fidelis Endpoint Platform.exe"
REM C:\Windows\System32\cmd.exe /k %WINDIR%\System32\bitsadmin.exe /transfer "Fidelis" "http://server.local/AgentSetup.txt" "%TEMP%\AgentSetup.txt"

REM -- Copy Files
XCOPY /y /f "F:\Fidelis Endpoint Platform.exe" "%TEMP%"
XCOPY /y /f "F:\AgentSetup.txt" "%TEMP%"

REM -- Install Agent
IF EXIST "%TEMP%\Fidelis Endpoint Platform.exe" (
  IF EXIST "%TEMP%\AgentSetup.txt" (
    C:\Windows\System32\cmd.exe /k "%TEMP%\Fidelis Endpoint Platform.exe" /install /quiet /norestart config_path="%TEMP%\AgentSetup.txt"
    ) ELSE (
    EXIT 1
  )
  ) ELSE (
  EXIT 1
)

REM -- Cleanup
DEL "%TEMP%\Fidelis Endpoint Platform.exe" /f /q
DEL "%TEMP%\AgentSetup.txt" /f /q
NET USE f: /delete

:END
EXIT 0
