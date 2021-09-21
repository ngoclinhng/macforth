global _main

%include "macforth.inc"
%include "words.inc"

native "push-three-numbers", push_three_numbers
    push ARG0
    push ARG1
    push ARG2
    jmp next

native "check-and-terminate", check_and_terminate
    pop rdi
    call printi

    mov rdi, SP_CHAR_CODE
    call printc

    pop rdi
    call printi

    mov rdi, SP_CHAR_CODE
    call printc

    pop rdi
    call printi

    mov rdi, RIP_REL(stack_base)
    sub rdi, rsp
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata
interpreter_stub:
    dq code_field_addr(push_three_numbers)
    dq code_field_addr(display_stack)
    dq code_field_addr(check_and_terminate)
