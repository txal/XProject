@echo off

echo ¿½±´µ½RPGGame
xcopy Libs ..\..\RPGGame\trunk\Libs /e /y
xcopy Source\Include ..\..\RPGGame\trunk\Src\Include /e /y

echo ¿½±´µ½RPGGame1
xcopy Libs ..\..\RPGGame1\trunk\Libs /e /y
xcopy Source\Include ..\..\RPGGame1\trunk\Src\Include /e /y

echo ¿½±´µ½Game
xcopy Libs ..\..\Game\trunk\Libs /e /y
xcopy Source\Include ..\..\Game\trunk\Src\Include /e /y

echo ¿½±´µ½PandaRC
xcopy Libs\Win32\* ..\..\..\PandaRC\Libs /e /y
xcopy Source\Include ..\..\..\PandaRC\Include /e /y