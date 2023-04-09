# Intel 8080 Emulator written in zig (0.10.1)
In an effort to learn about emulators and zig together,
I decided to work on this intel 8080 emulator in zig as it
is a well-documented architecture with plenty of existing
emulators.

My goal is to implement a proper debugging interface, snapshot support,
as well as a drawn window that emulates hardware inputs

## Feature(s?)
- Debugging interface for single stepping, viewing/modifying registers, etc
- That's about it for now :p

## Build instructions
    zig build
Executable will be generated in (project_root)/zig-out/bin/zigEmu
