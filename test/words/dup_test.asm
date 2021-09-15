global _main

%include "macforth.inc"
%include "words.inc"

%define NUM 5

native "push-integer", push_integer
    push NUM
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-dup", check_dup
    ; Make sure that rsp has been decremented by 8.
    mov rax, RIP_REL(tos_addr)
    sub rax, 8
    cmp rax, rsp
    jne .tos_addr_error

    ; Make sure TOS is NUM.
    cmp qword [rsp], NUM
    jne .tos_error

    ; Also make sure that NOS is NUM.
    cmp qword [rsp + 8], NUM
    jne .nos_error

    ; Seem OK to me
    lea rdi, RIP_REL(ok_msg)
    call prints
    jmp next
.tos_addr_error:
    lea rdi, RIP_REL(tos_addr_error_msg)
    call prints
    jmp next
.tos_error:
    lea rdi, RIP_REL(tos_error_msg)
    call prints
    jmp next
.nos_error:
    lea rdi, RIP_REL(nos_error_msg)
    call prints
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
    dq code_field_addr(push_integer)
    dq code_field_addr(dup)
    dq code_field_addr(check_dup)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: TOS's address is wrong", 0
tos_error_msg: db "Error: TOS is wrong", 0
nos_error_msg: db "Error: NOS is wrong", 0
ok_msg: db "OK", 0

section .data
tos_addr: dq 0
