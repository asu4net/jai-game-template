@echo off
jai -x64 build.jai - -imgui -editor -ecs -silent && cd bin && game.exe