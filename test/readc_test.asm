%include "utils.inc"

global _main

section .text
_main:
    call readc
    mov rdi, rax
    call exit
