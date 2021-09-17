global _main

%include "macforth.inc"
%include "words.inc"

native "push-number", push_number
    push ARG0
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-tos-addr", check_tos_addr
    ; Make sure that rsp has been incremented by 8
    mov rax, RIP_REL(tos_addr)
    add rax, 8
    cmp rax, rsp
    jne .tos_addr_error
    jmp next
.tos_addr_error:
    lea rdi, RIP_REL(tos_addr_error_msg)
    call prints
    jmp code_addr(terminate)

native "nozero", nozero
    lea rdi, RIP_REL(nozero_msg)
    call prints
    jmp next

native "iszero", iszero
    lea rdi, RIP_REL(iszero_msg)
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
    dq code_field_addr(push_number)
    gotz .zero_branch
    dq code_field_addr(check_tos_addr)
    dq code_field_addr(nozero)
    dq code_field_addr(terminate)
.zero_branch:
    dq code_field_addr(check_tos_addr)
    dq code_field_addr(iszero)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: rsp has been changed unexpectedly", 0
nozero_msg: db "NOZERO", 0
iszero_msg: db "ISZERO", 0

section .data
tos_addr: dq 0
