global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "FOO", 3, FOO, F_HIDDEN
    next

native "BAR", 3, BAR, F_IMMEDIATE
    next

native "BAZ", 3, BAZ, F_HIDDEN | F_IMMEDIATE
    next

native "PUSH-DATA", 9, PUSH_DATA
    lea rax, riprel(string)
    push rax
    push length
    next

native "CHAO", 4, CHAO
    pop rax
    test rax, rax
    jz .not_found

%ifdef ARG1
    lea rdi, riprel(head_field_addr(ARG1))
    cmp rax, rdi
    jne .error

    lea rdi, riprel(found_msg)
    call print_string
%endif

    jmp .check_stack
.not_found:
    lea rdi, riprel(not_found_msg)
    call print_string
    jmp .check_stack
.error:
    lea rdi, riprel(error_msg)
    call print_string
    jmp .check_stack
.check_stack:
    mov rdi, -1                 ; -1 means stack error
    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .exit
    xor rdi, rdi                ; 0 means OK
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata

interpreter_stub:
    dq code_field_addr(PUSH_DATA)
    dq code_field_addr(FIND_NAME)
    dq code_field_addr(CHAO)

string: db ARG0
length equ $ - string

found_msg: db "found", 0
not_found_msg: db "not_found", 0
error_msg: db "error", 0
