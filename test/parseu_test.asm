%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str
    call parseu

    push rdx
    mov rdi, rax
    call printu

    pop rdi
    jmp exit

section .data
str: db ARG0, 0
