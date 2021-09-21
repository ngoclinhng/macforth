global _main

%include "macforth.inc"
%include "words.inc"

native "push-two-numbers", push_two_numbers
    mov RIP_REL(rstack_before), rstack
    push ARG0
    push ARG1
    mov RIP_REL(stack_before), rsp
    jmp next

native "check-rstack-and-terminate", check_rstack_and_terminate
    ; rstack is expected to be decremented by 8.
    mov rax, RIP_REL(rstack_before)
    sub rax, 8
    cmp rax, rstack
    jne .rstack_error

    ; rsp is expected to be incremented by 8
    mov rax, RIP_REL(stack_before)
    add rax, 8
    cmp rsp, rax
    jne .stack_error

    ; stdout is expected to be 'ARG0 ARG1'.

    mov rdi, [rsp]
    call printi

    mov rdi, SP_CHAR_CODE
    call printc

    mov rdi, [rstack]
    call printi

    xor rdi, rdi
    jmp exit

.rstack_error:
    lea rdi, RIP_REL(rstack_error_msg)
    call prints
    xor rdi, rdi
    jmp exit

.stack_error:
    lea rdi, RIP_REL(stack_error_msg)
    call prints
    xor rdi, rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(push_two_numbers)
    dq code_field_addr(to_r)
    dq code_field_addr(check_rstack_and_terminate)

rstack_error_msg: db "Error: rstack has been changed unexpectedly", 0
stack_error_msg: db "Error: rsp has been changed unexpectedly", 0

section .data
rstack_before: dq 0
stack_before: dq 0
