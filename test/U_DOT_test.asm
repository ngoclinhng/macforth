global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "INIT-DATA", 9, INIT_DATA
    push ARG0
    mov qword riprel(base), ARG1
    next

native "CHAO", 4, CHAO
    mov rax, riprel(stack_base)
    cmp rsp, rax
    jne .stack_error

    xor rdi, rdi
    jmp .exit
.stack_error:
    mov rdi, 1
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata
interpreter_stub:
    dq code_field_addr(INIT_DATA)
    dq code_field_addr(U_DOT)
    dq code_field_addr(CHAO)
