global _main

%include "macforth.inc"
%include "words.inc"

native "before-colon", before_colon
    lea rdi, RIP_REL(col_msg)
    call prints
    jmp next

native "foo", foo
    lea rdi, RIP_REL(foo_msg)
    call prints
    jmp next

native "bar", bar
    lea rdi, RIP_REL(bar_msg)
    call prints
    rpop pc
    jmp next

colon "foobar", foobar
    dq code_field_addr(foo)
    dq code_field_addr(bar)

native "terminate", terminate
    lea rdi, RIP_REL(bye_msg)
    call prints
    xor rdi, rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(before_colon)
    dq code_field_addr(foobar)
    dq code_field_addr(terminate)

col_msg: db "colon: ", 0
foo_msg: db "foo ", 0
bar_msg: db "bar. ", 0
bye_msg: db "Bye", 0
