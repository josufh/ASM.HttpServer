ASM = nasm
LD = ld
ASM_FLAGS = -f elf64 -g
LD_FLAGS = -static

SRC = server.asm
OBJ = server.o
OUT = server

all: $(OUT)

$(OUT): $(OBJ)
	$(LD) $(LD_FLAGS) -o $(OUT) $(OBJ)
	rm -f $(OBJ)

$(OBJ): $(SRC)
	$(ASM) $(ASM_FLAGS) -o $(OBJ) $(SRC)

clean:
	rm -f $(OBJ) $(OUT)

