global _main

%include "macforth.inc"
%include "words.inc"

native "push-data", push_data
    ; Push char
    push ARG0

    ; Push c-addr
    lea rax, RIP_REL(c_addr)
    push rax

    jmp next

native "check-and-terminate", check_and_terminate
    ; Check stack
    mov rax, RIP_REL(stack_base)
    cmp rax, rsp
    jne .error

    ; Print string
    lea rdi, RIP_REL(c_addr)
    call prints

    movzx rdi, byte RIP_REL(c_addr)
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
    dq code_field_addr(push_data)
    dq code_field_addr(c_store)
    dq code_field_addr(check_and_terminate)

section .data
c_addr:
    db 0
    db 'END',0
