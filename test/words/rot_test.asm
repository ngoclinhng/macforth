global _main

%include "macforth.inc"
%include "words.inc"

native "setup", setup
    push ARG0
    push ARG1
    push ARG2
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-rot", check_rot
    ; Make sure rsp did not change.
    cmp rsp, RIP_REL(tos_addr)
    jne .tos_addr_error

    ; print TOS
    pop rdi
    call printi

    ; print space
    mov rdi, ' '
    call printc

    ; print NOS
    pop rdi
    call printi

    ; print space
    mov rdi, ' '
    call printc

    ; Check Third Element
    pop rdi
    call printi

    jmp next
.tos_addr_error:
    lea rdi, RIP_REL(tos_addr_error_msg)
    call prints
    jmp next

native "terminate", terminate
    xor rdi, rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(setup)
    dq code_field_addr(rot)
    dq code_field_addr(check_rot)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: rsp has changed", 0

section .data
tos_addr: dq 0
