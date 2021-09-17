global _main

%include "macforth.inc"
%include "words.inc"

native "push-numbers", push_numbers
    push ARG0
    push ARG1
    push ARG2
    push ARG3
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-tos-addr", check_tos_addr
    mov rax, RIP_REL(tos_addr)
    add rax, 8
    cmp rax, rsp
    jne .tos_addr_error
    jmp next
.tos_addr_error:
    lea rdi, RIP_REL(tos_addr_error_msg)
    call prints
    jmp code_addr(terminate)

native "print-stack", print_stack
    pop rdi
    call printi

    mov rdi, ' '
    call printc

    pop rdi
    call printi

    mov rdi, ' '
    call printc

    pop rdi
    call printi

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
    dq code_field_addr(push_numbers)
    dq code_field_addr(drop)
    dq code_field_addr(check_tos_addr)
    dq code_field_addr(print_stack)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: rsp has been changed unexpectedly", 0

section .data
tos_addr: dq 0
