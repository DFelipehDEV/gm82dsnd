@echo off

cmake -A Win32 -B build && cmake --build build --config Debug

del .\build\Release\gm82dsnd.dll
move .\build\Debug\gm82dsnd.dll .\build\Release\gm82dsnd.dll

python gm82gex.py gm82dsnd.gej

pause
