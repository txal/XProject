@echo off

echo 打包运行环境
del Runtime.zip /Q
mkdir Runtime
xcopy /y/f .\*exe Runtime
xcopy /y/f .\*pdb Runtime
xcopy /y/f .\*lib Runtime
xcopy /y/f .\*ilk Runtime
xcopy /y/f .\*exp Runtime
xcopy /y/f .\*dll Runtime
7z a -tzip Runtime.zip Runtime
rd /s/q Runtime


pause