%include "utils.inc"

global _main

section .text
_main:
    lea rdi, [rel str1]
    lea rsi, [rel str2]

    mov [rel before_stack], rsp
    call istrequ
    cmp rsp, [rel before_stack]
    jne .error

    mov rdi, rax
    jmp exit

.error:
    mov rdi, 2
    jmp exit

section .data
str1: db ARG0, 0
str2: db ARG1, 0
before_stack: dq 0
