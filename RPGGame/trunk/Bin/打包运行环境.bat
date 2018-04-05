@echo off

echo 打包运行环境
del Runtime.zip /Q

mkdir Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*exe Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*pdb Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*lib Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*ilk Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*exp Runtime\_LocalServer
xcopy /y/f .\_LocalServer\*dll Runtime\_LocalServer

mkdir Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*exe Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*pdb Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*lib Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*ilk Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*exp Runtime\_RobotClient
xcopy /y/f .\_RobotClient\*dll Runtime\_RobotClient

mkdir Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*exe Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*pdb Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*lib Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*ilk Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*exp Runtime\_RouterServer
xcopy /y/f .\_RouterServer\*dll Runtime\_RouterServer

mkdir Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*exe Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*pdb Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*lib Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*ilk Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*exp Runtime\_WorldServer
xcopy /y/f .\_WorldServer\*dll Runtime\_WorldServer

7z a -tzip Runtime.zip Runtime\_LocalServer
7z a -tzip Runtime.zip Runtime\_RobotClient
7z a -tzip Runtime.zip Runtime\_RouterServer
7z a -tzip Runtime.zip Runtime\_WorldServer
rd /s/q Runtime


pause