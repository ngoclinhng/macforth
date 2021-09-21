global _main

%include "macforth.inc"
%include "words.inc"

native "push-addr", push_addr
    lea rax, RIP_REL(addr)
    push rax

    mov RIP_REL(stack_before), rsp
    jmp next

native "check-and-terminate", check_and_terminate
    ; Check rsp
    mov rax, RIP_REL(stack_before)
    cmp rax, rsp
    jne .error

    ; Pop and print TOS
    pop rdi
    call printi

    xor rdi, rdi
    jmp exit

.error:
    mov rdi, 1
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(push_addr)
    dq code_field_addr(fetch)
    dq code_field_addr(check_and_terminate)

section .data
addr: dq ARG0
stack_before: dq 0
