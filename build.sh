#!/bin/bash

nasm -f elf64 -g server.asm -o build/server.o
ld build/server.o -o build/server
