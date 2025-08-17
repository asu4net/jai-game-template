@echo off
cd ../../ && jai -x64 build.jai - -imgui -editor -ecs && cd bin && game.exe