global _main

%include "macforth.inc"

;; Dictionary.

%include "words.inc"

native "foo", foo
    ; Check Working register (w).
    lea rdi, RIP_REL(code_field_addr(foo))
    cmp w, rdi
    jnz error

    ; Check pc
    lea rdi, RIP_REL(interpreter_stub + 8)
    cmp pc, rdi
    jnz error

    ; Check [pc]
    lea rdi, RIP_REL(code_field_addr(bar))
    cmp rdi, qword [pc]
    jnz error

    jmp next

native "bar", bar
    ; Check Working register (w).
    lea rdi, RIP_REL(code_field_addr(bar))
    cmp w, rdi
    jnz error

    ; Check pc
    lea rdi, RIP_REL(interpreter_stub + 16)
    cmp pc, rdi
    jnz error

    ; Check [pc]
    lea rdi, RIP_REL(code_field_addr(quit))
    cmp rdi, qword [pc]
    jnz error

    jmp next

native "quit", quit
    ; Check Working register (w).
    lea rdi, RIP_REL(code_field_addr(quit))
    cmp w, rdi
    jnz error

    ; Check pc
    lea rdi, RIP_REL(interpreter_stub + 24)
    cmp pc, rdi
    jnz error

    ; Ok
    xor rdi, rdi
    jmp exit

;; This must be included after dictionary.
%include "mem.inc"

section .text

error:
    mov rdi, 1
    jmp exit

_main:
    jmp code_addr(init)

section .rodata
interpreter_stub:
    dq code_field_addr(foo)
    dq code_field_addr(bar)
    dq code_field_addr(quit)
