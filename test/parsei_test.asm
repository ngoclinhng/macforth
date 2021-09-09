%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str
    call parsei

    push rdx
    mov rdi, rax
    call printi

    pop rdi
    jmp exit

section .data
str: db ARG0, 0
