global _main

%include "macforth.inc"
%include "words.inc"

native "push-three-numbers", push_three_numbers
    rpush ARG0
    rpush ARG1
    rpush ARG2
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
    ; Check rstack
    lea rax, RIP_REL(rstack_base)
    add rax, 8 * RSTACK_SIZE
    cmp rax, rstack
    jne .rstack_error

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
    dq code_field_addr(push_three_numbers)
    dq code_field_addr(r_from)
    dq code_field_addr(r_from)
    dq code_field_addr(r_from)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(print_space)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(print_space)
    dq code_field_addr(remove_and_print_tos)
    dq code_field_addr(terminate)
