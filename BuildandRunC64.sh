#!/bin/sh

VC64=/Users/jules/Desktop/EMU/C64/VirtualC64.app/Contents/MacOS/VirtualC64
OUTPUT=Game
INPUT=main

if [ -f "build/$OUTPUT.nprg" ]; then
    echo "Dxeleting $OUTPUT.prg"
    rm -fr "build/$OUTPUT.prg"
fi

cl65 -v -g -o "build/$OUTPUT.prg" -u __EXEHDR__ -t c64 -C "cfg/C64.cfg" "src/$INPUT.asm"

if [ -f "src/$INPUT.o" ]; then
    echo "Cleaning $INPUT.o"
    rm -rf src/$INPUT.o
fi

# if [ -f "build/$OUTPUT.prg" ]; then
#     echo "Launching $OUTPUT.prg"
#     VC64 build/$OUTPUT.prg &
# fi