@echo off
title Servidor Socket.IO Local - RAPH
echo ====================================================
echo  Iniciando Servidor Socket.IO de Desarrollo RAPH...
echo ====================================================
cd /d "%~dp0\socket-dev-server"
node server.js
pause
