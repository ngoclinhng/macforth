global _main

%include "macforth.inc"
%include "words.inc"

native "push-three-numbers", push_three_numbers
    push ARG0
    push ARG1
    push ARG2
    jmp next

native "print-space", print_space
    mov rdi, ' '
    call printc
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
    dq code_field_addr(push_three_numbers)
    dq code_field_addr(dot)
    dq code_field_addr(print_space)
    dq code_field_addr(dot)
    dq code_field_addr(print_space)
    dq code_field_addr(dot)
    dq code_field_addr(terminate)
