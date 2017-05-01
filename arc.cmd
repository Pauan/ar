@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
REM SET me=%~n0
SET arc_dir=%~dp0

racket %arc_dir%arc %*

ENDLOCAL
