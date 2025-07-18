# What will become a Web Runtime in assembly?

## Compile instructions

nasm -f elf64 -g server.asm && ld server.o -static -o server

## Run with strace to debug ezpz

strace ./server

## Costumization

In `contants.inc` there is a PORT constant, you can change the port there.

## TODO

* Makefile: Done 7/18
