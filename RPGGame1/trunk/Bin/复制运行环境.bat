@echo off

echo 复制运行环境

set target=E:\svnmengzhu\trunk\Server\_LocalServer
xcopy /y/f .\_LocalServer\*exe %target%
xcopy /y/f .\_LocalServer\*pdb %target%
xcopy /y/f .\_LocalServer\*lib %target%
xcopy /y/f .\_LocalServer\*ilk %target%
xcopy /y/f .\_LocalServer\*exp %target%
xcopy /y/f .\_LocalServer\*dll %target%

set target=E:\svnmengzhu\trunk\Server\_RobotClient
xcopy /y/f .\_RobotClient\*exe %target%
xcopy /y/f .\_RobotClient\*pdb %target%
xcopy /y/f .\_RobotClient\*lib %target%
xcopy /y/f .\_RobotClient\*ilk %target%
xcopy /y/f .\_RobotClient\*exp %target%
xcopy /y/f .\_RobotClient\*dll %target%

set target=E:\svnmengzhu\trunk\Server\_WorldServer
xcopy /y/f .\_WorldServer\*exe %target%
xcopy /y/f .\_WorldServer\*pdb %target%
xcopy /y/f .\_WorldServer\*lib %target%
xcopy /y/f .\_WorldServer\*ilk %target%
xcopy /y/f .\_WorldServer\*exp %target%
xcopy /y/f .\_WorldServer\*dll %target%


pause