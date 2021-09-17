global _main

%include "macforth.inc"
%include "words.inc"

native "push-undef-word-name", push_undef_word_name
    push ARG1                   ; Exit status code (also TOS after printe)
    lea rax, RIP_REL(undef_word_name)
    push rax
    jmp next

native "terminate", terminate
    pop rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(push_undef_word_name)
    dq code_field_addr(printe)
    dq code_field_addr(terminate)

undef_word_name: db ARG0, 0
