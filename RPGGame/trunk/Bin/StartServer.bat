call StartPlayerDB.bat

call StartRouterServer.bat
ping 127.0.0.1 -n 2
call StartLogServer.bat
ping 127.0.0.1 -n 2
call StartGlobalServer.bat
call StartLogicServer.bat
call StartGateServer.bat
