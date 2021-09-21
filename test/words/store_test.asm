global _main

%include "macforth.inc"
%include "words.inc"

native "push-data", push_data
    ; Push x
    push ARG0

    ; Push a-addr
    lea rax, RIP_REL(addr)
    push rax

    jmp next

native "check-and-terminate", check_and_terminate
    ; Check stack
    mov rax, RIP_REL(stack_base)
    cmp rax, rsp
    jne .error

    ; Print stored value
    mov rdi, RIP_REL(addr)
    call printi

    xor rdi, rdi
    jmp exit

.error:
    mov rdi, 1
    jmp exit


%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata
interpreter_stub:
    dq code_field_addr(push_data)
    dq code_field_addr(store)
    dq code_field_addr(check_and_terminate)

section .bss
addr: resq 1
