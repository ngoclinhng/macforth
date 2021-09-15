global _main

%include "macforth.inc"
%include "words.inc"

native "save-tos-addr", save_tos_addr
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-word", check_word
    ; Make sure TOS's address did not change.
    cmp RIP_REL(tos_addr), rsp
    jne .tos_addr_error

    ; Make sure TOS is string's length.
    lea rdi, RIP_REL(input_buffer)
    call strlen
    cmp rax, [rsp]
    jne .tos_error

    ; Print the string that has just been read.
    lea rdi, RIP_REL(input_buffer)
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
    dq code_field_addr(ibuf)
    dq code_field_addr(save_tos_addr)
    dq code_field_addr(word)
    dq code_field_addr(check_word)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: TOS's address is incorrect", 0
tos_error_msg: db "Error: TOS is not string's length", 0

section .data
tos_addr: dq 0                  ; TOS address
