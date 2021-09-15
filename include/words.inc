;; ( addr -- header_field_add | 0 )
;; Takes as input an address of a null-terminated string (`addr`) and returns
;; the address of the Header Field of the word in the word in the dictionary
;; whose name matches the given string. If no such word was found, 0 is
;; returned instead.
native "find", find
    ; Reads last word in the dictionary into rsi. To be precise, the content
    ; of the memory cell designated by `last_word_ptr` is the address of the
    ; last word's Header Field
    mov rsi, RIP_REL(last_word_ptr)
.loop:
    ; addr of null-terminated string (1st argument to strequ)
    mov rdi, [rsp]

    ; address of the word's Name Field (2nd argument to strequ). We also
    ; have to save rsi here so that it will survive strequ call.
    push rsi
    add rsi, NAME_FIELD_OFFSET

    ; Compares two strings and restores previously saved rsi.
    call strequ
    pop rsi

    ; If equal rax = 1, otherwise 0
    test rax, rax
    jnz .found

    ; rsi stores the address of the current word's Header Field. The first
    ; cell (8 bytes) of this field is yet another address - the address of
    ; the previous word's Header Field. If rsi is zero we know that we
    ; have reached the end of the dictionary and no such word was found.
    mov rsi, [rsi]
    test rsi, rsi
    jnz .loop
.not_found:
    mov qword [rsp], 0
    jmp next
.found:
    mov [rsp], rsi
    jmp next

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
