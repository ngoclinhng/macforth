global _main

%include "macros.inc"
%include "utils.inc"
%include "wordlist.inc"

%define RSTACK_ERROR_CODE 1
%define STACK_BASE_ERROR_CODE 2
%define STATE_ERROR_CODE 3
%define LASTWORD_ERROR_CODE 4
%define INPUT_BUFFER_OFFSET_ERROR_CODE 5
%define INPUT_BUFFER_LENGTH_ERROR_CODE 6
%define BASE_ERROR_CODE 7

native "CHECK", 5, CHECK
    ; Check rstack
    lea rax, riprel(rstack_top)
    cmp rstack, rax
    jne .rstack_error

    ; Check data stack base
    mov rax, riprel(stack_base)
    cmp rax, rsp
    jne .stack_base_error

    ; Check state
    mov rax, riprel(state)
    test rax, rax
    jnz .state_error

    ; Check latest
    lea rax, riprel(head_field_addr(CHECK))
    cmp rax, riprel(latest)
    jne .lastword_error

    ; Check input buffer offset
    mov rax, riprel(input_buffer_offset)
    test rax, rax
    jnz .input_buffer_offset_error

    ; Check input buffer length
    mov rax, riprel(input_buffer_length)
    test rax, rax
    jnz .input_buffer_length_error

    ; Check base
    mov rax, riprel(base)
    cmp rax, 10
    jne .base_error

    ; Ok
    xor rdi, rdi
    jmp .exit
.rstack_error:
    mov rdi, RSTACK_ERROR_CODE
    jmp .exit
.stack_base_error:
    mov rdi, STACK_BASE_ERROR_CODE
    jmp .exit
.state_error:
    mov rdi, STATE_ERROR_CODE
    jmp .exit
.lastword_error:
    mov rdi, LASTWORD_ERROR_CODE
    jmp .exit
.input_buffer_offset_error:
    mov rdi, INPUT_BUFFER_OFFSET_ERROR_CODE
    jmp .exit
.input_buffer_length_error:
    mov rdi, INPUT_BUFFER_LENGTH_ERROR_CODE
    jmp .exit
.base_error:
    mov rdi, BASE_ERROR_CODE
.exit:
    mov rax, SYSCALL_EXIT
    syscall

%include "datasegment.inc"

section .text
_main:
    jmp code_addr(INIT)

section .rodata
interpreter_stub:
    dq code_field_addr(CHECK)
