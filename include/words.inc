;; Initialization.
native "init", init
    mov qword RIP_REL(state_ptr), 0
    mov rstack, rstack_start
    mov pc, interpreter_stub

    cmp qword RIP_REL(stack_base), 0
    je .first

    mov rsp, RIP_REL(stack_base)
    jmp next
.first:
    mov RIP_REL(stack_base), rsp
    jmp next

;; Since each test case will define its own interpreter.
;; TODO: this is just placeholder for now.
%ifndef TEST
section .rodata
interpreter_stub: dq 0
%endif
