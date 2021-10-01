global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "CHAO", 4, CHAO
    ; Check TOS
    pop rax
    lea rdi, riprel(latest)
    cmp rax, rdi
    jne .tos_error

    ; Check latest.
    mov rax, [rax]
    lea rdi, riprel(head_field_addr(CHAO))
    cmp rax, rdi
    jne .latest_error

    ; Check stack
    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .stack_error

    ; Ok
    xor rdi, rdi
    jmp .exit
.tos_error:
    mov rdi, 1
    jmp .exit
.latest_error:
    mov rdi, 2
    jmp .exit
.stack_error:
    mov rdi, 3
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata
interpreter_stub:
    dq code_field_addr(LATEST)
    dq code_field_addr(CHAO)
