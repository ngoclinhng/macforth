global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "PUSHX", 5, PUSHX
    push ARG0
    next

native "CHAO", 4, CHAO
    mov rax, riprel(stack_base)
    cmp rax, rsp
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
    dq code_field_addr(PUSHX)
    dq code_field_addr(EMIT)
    dq code_field_addr(CHAO)
