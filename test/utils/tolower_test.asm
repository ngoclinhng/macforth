global _main

%include "utils.inc"

section .text
_main:
    mov rdi, ARG0
    call tolower
    mov rdi, rax
    jmp exit
