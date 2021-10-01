global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

native "CHAO", 4, CHAO
    pop rsi
    pop rdi

    push rsi
    call print_char_string
    pop rdi

    mov rax, riprel(stack_base)
    cmp rax, rsp
    je .exit
.stack_error:
    mov rdi, -1
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata
interpreter_stub:
    dq code_field_addr(PARSE_NAME)
    dq code_field_addr(CHAO)
