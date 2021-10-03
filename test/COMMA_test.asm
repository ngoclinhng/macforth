global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "PUSH-NUMBERS", 12, PUSH_NUMBERS
    push ARG0
    push ARG1
    push ARG2

    mov rax, riprel(here)
    mov riprel(here_before), rax
    next

native "CHAO", 4, CHAO
    ; Check stack
    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .stack_error

    ; check third number
    mov rax, riprel(here_before)
    cmp qword [rax], ARG2
    jne .third_error

    ; Check second number
    add rax, 8
    cmp qword [rax], ARG1
    jne .second_error

    ; Check first number
    add rax, 8
    cmp qword [rax], ARG0
    jne .first_error

    ; Check here
    add rax, 8
    cmp riprel(here), rax
    jne .here_error

    ; Ok
    xor rdi, rdi
    jmp .exit
.stack_error:
    mov rdi, 1
    jmp .exit
.first_error:
    mov rdi, 2
    jmp .exit
.second_error:
    mov rdi, 3
    jmp .exit
.third_error:
    mov rdi, 4
    jmp .exit
.here_error:
    mov rdi, 5
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata

interpreter_stub:
    dq code_field_addr(PUSH_NUMBERS)
    dq code_field_addr(COMMA)
    dq code_field_addr(COMMA)
    dq code_field_addr(COMMA)
    dq code_field_addr(CHAO)

section .bss
here_before: resq 1
