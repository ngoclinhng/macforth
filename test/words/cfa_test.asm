global _main

%include "macforth.inc"
%include "words.inc"

;; Push string address
native "setup", setup
    lea rax, RIP_REL(str)
    push rax
    jmp next

native "before-cfa", before_cfa
    cmp qword [rsp], 0
    je .not_found

    mov RIP_REL(tos_addr), rsp
    jmp next

;; If TOS is zero, we know that no such word was found.
;; In this case, there is no need to proceed.
.not_found:
    lea rdi, RIP_REL(not_found_msg)
    call prints
    jmp code_addr(terminate)

native "after-cfa", after_cfa
    ; Make sure rsp did not change
    cmp RIP_REL(tos_addr), rsp
    jne .tos_addr_error

;; Make sure TOS is now the Code Field Address of some word.
%ifdef ARG1
    lea rax, RIP_REL(code_field_addr(ARG1))
    cmp rax, [rsp]
    jne .tos_error
%endif

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
    dq code_field_addr(setup)
    dq code_field_addr(find)
    dq code_field_addr(before_cfa)
    dq code_field_addr(cfa)
    dq code_field_addr(after_cfa)
    dq code_field_addr(terminate)

not_found_msg: db "No such word was found", 0
tos_addr_error_msg: db "Error: rsp has changed unexpectedly", 0
tos_error_msg: db "Error: TOS is not the expected Code Field Address", 0
ok_msg: db "OK", 0

section .data
str: db ARG0, 0
tos_addr: dq 0
