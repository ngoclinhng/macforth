;; ( a -- a a)
;; Duplicates the TOS (top-of-stack) into NOS (next-on-stack).
;; Sample image of the Paramater Strack before and after `dup`:
;;
;;   cell#  | initial |  dup
;;   -------------------------
;;     0    |   -16   |  -16              (TOS)
;;     1    |    73   |  -16              (NOS)
;;     2    |     5   |   73
;;     3    |         |    5
;;     4    |         |
native "dup", dup
    push qword [rsp]
    jmp next

;; ( a b c -- b c a)
;; Rotates the top 3 numbers.
;; Sample image of the Paramater Stack before and after `rot`:
;;
;;   cell#  | initial |  rot
;;   -------------------------
;;     0    |   -16   |    5              (TOS)
;;     1    |    73   |  -16              (NOS)
;;     2    |     5   |   73
;;     3    |     2   |    2
;;     4    |         |
native "rot", rot
    pop rcx
    pop rdx
    pop rax
    push rdx
    push rcx
    push rax
    jmp next

;; ( input_buffer_addr -- length )
;; Reads a word from stdin (skip leading spaces) into the buffer starting at
;; the address `input_buffer_addr`. Word's length will be pushed onto the
;; Paramater Stack.
;; TODO: What if readw failed?
native "word", word
    pop rdi
    mov rsi, INPUT_BUFFER_SIZE
    call readw
    push rdx
    jmp next

;; ( addr -- header_field_addr | 0 )
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

;; ( header_field_addr -- code_field_addr )
;; Converts a word's Header Field Address to its Code Field Address
;; Consult `macros.inc` for the structure of a word.
native "cfa", cfa
    pop rsi
    add rsi, NAME_FIELD_OFFSET
.loop:
    mov al, [rsi]
    test al, al
    jz .end
    inc rsi
    jmp .loop
.end:
    add rsi, 2                  ; 1 for null-terminator + 1 for flags
    push rsi
    jmp next

;; ( -- input_buffer_addr )
;; Pushes the address of the input buffer onto the Paramater Stack.
native "ibuf", ibuf
    push_addr input_buffer
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
