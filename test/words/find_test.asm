global _main

%include "macforth.inc"

%include "words.inc"

native "foo", foo
    jmp next

native "bar", bar
    jmp next

native "baz", baz
    jmp next

native "push-string-addr", push_string_addr
    lea rax, RIP_REL(str)
    push rax
    mov RIP_REL(tos_addr), rsp
    jmp next

native "check-find", check_find
    ; Make sure address of TOS (rsp) did not change after find.
    cmp rsp, RIP_REL(tos_addr)
    jne .tos_addr_error

    cmp qword [rsp], 0
    je .not_found

    ; Make sure [rsp] is actually the address of the Header Field
    ; of the found word
%ifdef ARG1
    lea rdi, RIP_REL(head_field_addr(ARG1))
    cmp [rsp], rdi
    jne .tos_error
%endif

    lea rdi, RIP_REL(found_msg)
    call prints
    jmp next
.tos_addr_error:
    lea rdi, RIP_REL(tos_addr_error_msg)
    call prints
    jmp next
.not_found:
    lea rdi, RIP_REL(not_found_msg)
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
    dq code_field_addr(push_string_addr)
    dq code_field_addr(find)
    dq code_field_addr(check_find)
    dq code_field_addr(terminate)

tos_addr_error_msg: db "Error: rsp has changed!", 0
tos_error_msg: db "Error: TOS is not the address of Header Field", 0
not_found_msg: db "not_found", 0
found_msg: db "found", 0

section .data
str: db ARG0, 0
tos_addr: dq 0
