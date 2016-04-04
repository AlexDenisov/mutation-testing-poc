CC=~/Projects/LLVM/build_static/bin/clang

all:
	$(CC) -c -emit-llvm -g main.c sum.c
	$(CC) -S -emit-llvm -g main.c sum.c
