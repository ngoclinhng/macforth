global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "CHECK", 5, CHECK
    ; Check data stack
    mov rax, riprel(stack_base)
    sub rax, 8
    cmp rax, rsp
    jne .stack_error

    pop rdi
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
    dq code_field_addr(KEY)
    dq code_field_addr(CHECK)
