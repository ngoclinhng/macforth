global _main

%include "macforth.inc"
%include "words.inc"

;; ( addr -- )
native "print-message", print_message
    pop rdi
    call prints
    jmp next

;; ( tos -- )
native "terminate", terminate
    pop rdi
    call printi

    xor rdi, rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(lit)
    dq message
    dq code_field_addr(print_message)
    dq code_field_addr(lit)
    dq ARG1
    dq code_field_addr(terminate)

message: db ARG0, 32, 0
