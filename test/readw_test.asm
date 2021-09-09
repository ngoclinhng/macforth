%include "utils.inc"

global _main

%define BUFFER_SIZE 8

section .text
_main:
    mov rdi, buffer
    mov rsi, BUFFER_SIZE
    call readw

    test rax, rax
    jz .error

    push rdx
    mov rdi, rax
    call prints

    pop rdi
    call exit
.error:
    mov rdi, -1
    call exit

section .bss
buffer: resb BUFFER_SIZE               ; reserves 8 bytes
