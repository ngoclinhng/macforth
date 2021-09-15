global _main

%include "macforth.inc"

;; Dictionary
%include "words.inc"

native "check-init", check_init
    ; Make sure state is 0 (interpreting).
    cmp qword RIP_REL(state_ptr), 0
    jnz .state_error

    ; Make sure rstack (Return Stack Pointer) is correctly initialized.
    lea rdi, RIP_REL(rstack_start)
    cmp rstack, rdi
    jnz .rstack_error

    ; Make sure stack_base is correctly set up.
    cmp qword RIP_REL(stack_base), rsp
    jnz .stack_base_error

    ; Make sure last_word_ptr points to last word in the dictionary (`quit`)
    lea rdi, RIP_REL(head_field_addr(quit))
    cmp rdi, qword RIP_REL(last_word_ptr)
    jnz .last_word_error

    ; Everything seem OK to me!
    lea rdi, RIP_REL(ok_msg)
    call prints
    jmp next

.state_error:
    lea rdi, RIP_REL(state_error_msg)
    call prints
    jmp next

.rstack_error:
    lea rdi, RIP_REL(rstack_error_msg)
    call prints
    jmp next

.stack_base_error:
    lea rdi, RIP_REL(stack_base_error_msg)
    call prints
    jmp next

.last_word_error:
    lea rdi, RIP_REL(last_word_error_msg)
    call prints
    jmp next

; Last word here!
native "quit", quit
    xor rdi, rdi
    jmp exit

;; This must be included after dictionary.
%include "mem.inc"

section .text
_main:
    jmp code_addr(init)

section .rodata

interpreter_stub:
    dq code_field_addr(check_init)
    dq code_field_addr(quit)

state_error_msg: db "Error: expected state to be 0", 0
rstack_error_msg: db "Error: expected rstack to be equal to rstack_start", 0
stack_base_error_msg: db "Error: stack_base was not set up correctly", 0
last_word_error_msg: db "Error: last_word_ptr was not setup correctly", 0

ok_msg: db "OK",0
