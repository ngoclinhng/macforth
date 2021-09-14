%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str1
    mov rsi, str2
    call strequ
    mov rdi, rax
    jmp exit

section .data
str1: db ARG0, 0
str2: db ARG1, 0
