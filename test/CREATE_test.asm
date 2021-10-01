global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

%define LATEST_ERROR_CODE 1
%define LINK_ERROR_CODE 2
%define FLAGS_ERROR_CODE 3
%define LENGTH_ERROR_CODE 4
%define CODE_ERROR_CODE 5
%define HERE_ERROR_CODE 6
%define EXECUTE_ERROR_CODE 7
%define OK_CODE 8

native "SAVE-HERE", 9, SAVE_HERE
    mov rax, riprel(here)
    mov riprel(old_here), rax
    next

native "CHECK-LINK", 10, CHECK_LINK
    ; Check latest
    mov rdi, riprel(latest)     ; new latest
    cmp rdi, riprel(old_here)   ; vs old here
    jne .latest_error

    ; Check LINK
    mov rsi, [rdi]              ; LINK
    lea rax, riprel(head_field_addr(CHAO))
    cmp rax, rsi
    jne .link_error

    add rdi, 8
    push rdi
    next
.latest_error:
    mov rdi, LATEST_ERROR_CODE
    jmp exit
.link_error:
    mov rdi, LINK_ERROR_CODE
    jmp exit

native "CHECK-FLAGS", 11, CHECK_FLAGS
    pop rax                     ; FLAGS address
    cmp byte [rax], 0           ; expect no flags
    jne .flags_error

    inc rax
    push rax
    next
.flags_error:
    mov rdi, FLAGS_ERROR_CODE
    jmp exit

native "CHECK-LENGTH", 12, CHECK_LENGTH
    pop rax                     ; LENGTH address
    cmp byte [rax], ARG0        ; expect length to be ARG0
    jne .length_error

    inc rax
    push rax
    next
.length_error:
    mov rdi, LENGTH_ERROR_CODE
    jmp exit

native "CHECK-NAME", 10, CHECK_NAME
    pop rdi                     ; name's address
    mov rsi, ARG0               ; name's length

    push rdi
    call print_char_string
    pop rdi

    add rdi, ARG0
    add rdi, 0x7
    and rdi, ~0x7
    push rdi
    next

native "CHECK-CODE", 10, CHECK_CODE
    pop rax                     ; Code Field Address
    lea rdi, riprel(DOVAR)      ; DOVAR
    cmp rdi, [rax]
    jne .code_error

    add rax, 8
    push rax
    next
.code_error:
    mov rdi, CODE_ERROR_CODE
    jmp exit

native "CHECK-HERE", 10, CHECK_HERE
    pop rax                     ; Parameter Field Address
    mov rdi, riprel(here)       ; new here
    cmp rax, rdi
    jne .here_error
    next
.here_error:
    mov rdi, HERE_ERROR_CODE
    jmp exit

colon "EXECUTE-WORD", 12, EXECUTE_WORD
    dq code_field_addr(PARSE_NAME)
    dq code_field_addr(FIND_NAME)
    dq code_field_addr(TO_CFA)
    dq code_field_addr(EXECUTE)
    dq code_field_addr(EXIT)

native "CHECK-EXECUTE", 13, CHECK_EXECUTE
    pop rax
    mov rdi, riprel(here)
    cmp rax, rdi
    jne .execute_error
    next
.execute_error:
    mov rdi, EXECUTE_ERROR_CODE
    jmp exit

native "CHAO", 4, CHAO
    mov rdi, OK_CODE
    jmp exit

%include "datasegment.inc"

section .text

_main:
    jmp code_addr(INIT)

exit:
    mov rax, SYSCALL_EXIT
    syscall

section .rodata
interpreter_stub:
    dq code_field_addr(SAVE_HERE)
    dq code_field_addr(CREATE)
    dq code_field_addr(CHECK_LINK)
    dq code_field_addr(CHECK_FLAGS)
    dq code_field_addr(CHECK_LENGTH)
    dq code_field_addr(CHECK_NAME)
    dq code_field_addr(CHECK_CODE)
    dq code_field_addr(CHECK_HERE)
    dq code_field_addr(EXECUTE_WORD)
    dq code_field_addr(CHECK_EXECUTE)
    dq code_field_addr(CHAO)

section .bss
old_here: resq 1
