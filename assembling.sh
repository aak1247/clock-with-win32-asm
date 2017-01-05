ml -c -coff -Cp -nologo -I "f://masm32/include/" "clock.asm" && LINK32.EXE -SUBSYSTEM:WINDOWS -RELEASE -VERSION:4.0 -LIBPATH:"F:\masm32\lib" -OUT:"clock.exe" "clock.obj"
