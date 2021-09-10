%include "utils.inc"

%define BUFFER_SIZE 8

global _main

section .text
_main:
    mov rdi, src
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    call strcpy

    ; string is too long for the specified buffer
    test rax, rax
    jz .end

    ; print result to stdout
    push rax
    mov rdi, rax
    call prints

    ; compare the source and its copy
    pop rdi
    mov rsi, src
    call strequ

    ; exit status is the result of comparison
    mov rdi, rax
    jmp exit

.end:
    xor rdi, rdi
    jmp exit

section .data
src: db ARG0, 0

section .bss
buffer: resb BUFFER_SIZE        ; reserves 8 bytes
