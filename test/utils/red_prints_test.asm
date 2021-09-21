%include "utils.inc"

global _main

section .text
_main:
    mov rdi, str

    mov [rel stack_before], rsp
    call red_prints
    cmp rsp, [rel stack_before]
    jne .error

    xor rdi, rdi
    jmp exit

.error:
    mov rdi, 1
    jmp exit

section .data
str: db ARG0, 0
stack_before: dq 0
