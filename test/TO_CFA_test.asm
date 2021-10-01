global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "PUSH-HFA", 8, PUSH_HFA
    lea rax, riprel(head_field_addr(ARG0))
    push rax
    next

native "CHAO", 4, CHAO
    lea rax, riprel(code_field_addr(ARG0))
    pop rdx
    cmp rax, rdx
    jne .tos_error

    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .stack_error

    xor rdi, rdi
    jmp .exit
.tos_error:
    mov rdi, 1
    jmp .exit
.stack_error:
    mov rdi, 2
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata
interpreter_stub:
    dq code_field_addr(PUSH_HFA)
    dq code_field_addr(TO_CFA)
    dq code_field_addr(CHAO)
