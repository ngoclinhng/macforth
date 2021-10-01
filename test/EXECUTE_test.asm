global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "FOO", 3, FOO
    lea rdi, riprel(message)
    mov rsi, length
    call print_counted_string
    next

native "PUSH-FOO", 8, PUSH_FOO
    push length                 ; exit status code
    lea rax, riprel(code_field_addr(FOO))
    push rax
    next

native "CHAO", 4, CHAO
    pop rdi
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata

interpreter_stub:
    dq code_field_addr(PUSH_FOO)
    dq code_field_addr(EXECUTE)
    dq code_field_addr(CHAO)

message: db ARG0
length equ $ - message
