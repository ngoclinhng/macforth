global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "PUSH-STRING", 11, PUSH_STRING
    lea rax, riprel(string)
    push rax
    push length

    mov qword riprel(base), ARG1 ; base for conversion
    next

native "CHAO", 4, CHAO
    ; Check stack
    mov rax, riprel(stack_base)
    sub rax, 16
    cmp rax, rsp
    jne .stack_error

    pop rax                     ; flag
    test rax, rax
    jz .invalid_string

    pop rdi                     ; number
    cmp rdi, ARG2
    jne .error

    mov rsi, 10                 ; base is decimal
    call print_int              ; print number in decimal format.

    xor rdi, rdi
    jmp .exit
.invalid_string:
    mov rdi, 1
    jmp .exit
.error:
    mov rdi, 2
    jmp .exit
.stack_error:
    mov rdi, 3
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata

interpreter_stub:
    dq code_field_addr(PUSH_STRING)
    dq code_field_addr(STRING_TO_NUMBER)
    dq code_field_addr(CHAO)

string: db ARG0
length equ $ - string
