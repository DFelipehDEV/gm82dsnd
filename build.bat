@echo off

cmake -A Win32 -B build && cmake --build build --config Release

python gm82gex.py gm82dsnd.gej

pause
