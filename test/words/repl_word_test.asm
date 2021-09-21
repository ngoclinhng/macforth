global _main

%include "macforth.inc"
%include "words.inc"

native "check-and-terminate", check_and_terminate
    ; Prints string
    lea rdi, RIP_REL(input_buffer)
    call prints

    mov rdi, '('
    call printc

    ; Prints length
    pop rdi
    call printu

    ; Prints comma
    mov rdi, ','
    call printc

    ; Prints last char read.
    pop rdi
    call printu

    mov rdi, ')'
    call printc

    ; Status code is expected to be 0
    mov rdi, RIP_REL(stack_base)
    sub rdi, rsp
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata
interpreter_stub:
    dq code_field_addr(ibuf)
    dq code_field_addr(repl_word)
    dq code_field_addr(check_and_terminate)
