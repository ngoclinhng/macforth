global _main

%include "macforth.inc"
%include "words.inc"

native "foo", foo
    lea rdi, RIP_REL(message)
    call prints
    jmp next

native "foo-cfa", foo_cfa
    push ARG1                   ; exit status code (NOS)
    lea rax, RIP_REL(code_field_addr(foo))
    push rax                    ; (TOS)
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
    dq code_field_addr(foo_cfa)
    dq code_field_addr(execute)
    dq code_field_addr(terminate)

message: db ARG0, 0
