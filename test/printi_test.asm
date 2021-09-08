%include "utils.inc"

global _main

section .text
_main:
    mov rdi, ARG0
    call printi
    xor rdi, rdi
    call exit
