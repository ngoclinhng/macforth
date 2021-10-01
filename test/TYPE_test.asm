global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "PUSH-STRING", 11, PUSH_STRING
    lea rax, riprel(string)
    push rax
    push length
    next

native "CHAO", 4, CHAO
    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .stack_error

    mov rdi, length
    jmp .exit
.stack_error:
    mov rdi, -1
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata

interpreter_stub:
    dq code_field_addr(PUSH_STRING)
    dq code_field_addr(TYPE)
    dq code_field_addr(CHAO)

string: db ARG0
length equ $ - string
