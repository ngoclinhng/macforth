%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str
    call prints
    xor rdi, rdi
    call exit

section .data
str: ARG0
