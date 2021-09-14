;; Initialization.
native "init", init
    mov qword rip_rel(state_ptr), 0
    mov rstack, rstack_start
    mov pc, interpreter_stub

    cmp qword rip_rel(stack_base), 0
    je .first

    mov rsp, rip_rel(stack_base)
    jmp next
.first:
    mov rip_rel(stack_base), rsp
    jmp next

;; Since each test case will define its own interpreter.
;; TODO: this is just placeholder for now.
%ifndef TEST
section .rodata
interpreter_stub: dq 0
%endif
