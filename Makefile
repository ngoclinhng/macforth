NASM=nasm -f macho64 -Iinclude/
LD=ld -lSystem
MACFORTH_INCLUDES= include/macforth.inc include/words.inc include/mem.inc

all: bin/macforth

bin/macforth: obj/macforth.o obj/next.o obj/utils.o
	mkdir -p bin
	$(LD) -o $@ $^

obj/macforth.o: src/macforth.asm $(MACFORTH_INCLUDES)
	mkdir -p obj
	$(NASM) $< -o $@

obj/next.o: src/next.asm include/regs.inc
	mkdir -p obj
	$(NASM) $< -o $@

obj/utils.o: src/utils.asm include/constants.inc
	mkdir -p obj
	$(NASM) $< -o $@
