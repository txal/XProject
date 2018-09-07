@echo off

pushd ..
for %%b in (.\) do cd /d %%b
for /r %%c in (debug *.sdf x64 ipch) do if exist %%c (
	if exist %%c\nul (
		echo Del %%c
		rd /q/s "%%c"
	) else (
		echo Del %%c
		del /f/s/q "%%c"
	)
)

pause()