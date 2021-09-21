global _main

%include "macforth.inc"
%include "words.inc"

native "push-two-numbers", push_two_numbers
    rpush ARG0
    rpush ARG1
    jmp next

native "remove-and-print-tos", remove_and_print_tos
    pop rdi
    call printi
    jmp next

native "print-space", print_space
    mov rdi, SP_CHAR_CODE
    call printc
    jmp next

native "terminate", terminate
    ; check rstack
    lea rax, RIP_REL(rstack_base)
    add rax, (RSTACK_SIZE - 2) * 8
    cmp rax, rstack
    jne .rstack_error

    ; print rstack
    call printn
    rpop rdi
    call printi
    mov rdi, SP_CHAR_CODE
    call printc
    rpop rdi
    call printi

    ; Check rsp
    cmp rsp, RIP_REL(stack_base)
    jne .stack_error

    xor rdi, rdi
    jmp exit

.rstack_error:
    mov rdi, 1
    jmp exit

.stack_error:
    mov rdi, 2
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata
interpreter_stub:
    dq code_field_addr(push_two_numbers)
    dq code_field_addr(r_fetch)
    dq code_field_addr(r_fetch)
    dq code_field_addr(r_fetch)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(print_space)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(print_space)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(terminate)
