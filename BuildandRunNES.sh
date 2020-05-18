#!/bin/sh

VC64=/Users/jules/Desktop/EMU/C64/VirtualC64.app/Contents/MacOS/VirtualC64
OUTPUT=Game
INPUT=main

if [ -f "build/$OUTPUT.nes" ]; then
    echo "Deleting $OUTPUT.nes"
    rm -fr "build/$OUTPUT.nes"
fi

cl65 -o "build/$OUTPUT.nes" -t nes -C "cfg/NES.cfg" "src/$INPUT.asm"

if [ -f "src/$INPUT.o" ]; then
    echo "Cleaning $INPUT.o"
    rm -rf src/$INPUT.o
fi

# if [ -f "build/$OUTPUT.prg" ]; then
#     echo "Launching $OUTPUT.prg"
#     $VC64 build/$OUTPUT.prg &
# fi