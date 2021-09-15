global _main

%include "macforth.inc"
%include "words.inc"

native "save-tos-addr", save_tos_addr
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-ibuf", check_ibuf
    ; Make sure that rsp has been decremented by 8
    mov rax, RIP_REL(tos_addr)
    sub rax, 8
    cmp rax, rsp
    jne .tos_addr_error

    ; Make sure that the address of the input buffer is now TOS.
    lea rax, RIP_REL(input_buffer)
    cmp rax, [rsp]
    jne .tos_error

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

native "terminate", terminate
    xor rdi, rdi
    jmp exit

%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(save_tos_addr)
    dq code_field_addr(ibuf)
    dq code_field_addr(check_ibuf)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: TOS's address is wrong", 0
tos_error_msg: db "Error: TOS is not the address of the input buffer", 0
ok_msg: db "OK", 0

section .data
tos_addr: dq 0
