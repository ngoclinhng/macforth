%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str
    call strlen
    mov rdi, rax
    call exit

section .data
str: db 'Hello, world!',0
