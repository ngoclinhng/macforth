%ifndef MACFORTH_MEM_INC_
%define MACFORTH_MEM_INC_

;; IMPORTANT: this file should only be included after the dictionary!
;; (so that last_word_ptr points to the correct last word in the dictionary).

section .bss

;; Return Stack.
;; We pre-allocate 8 Kb (1024 * 8 bytes) for the return stack (which mean
;; it can store at most 1024 addresses!).
;;
;; lowest adress ----------> highest address
;; +-----------..............--------------+
;; +          RSTACK_SIZE * 8 bytes        +
;; +-----------..............--------------+
;; ^
;; |
;; rstack_base
rstack_base: resq RSTACK_SIZE

;; Changes to 1 if compiling, 0 by default.
state_ptr: resq 1

;; Input Buffer: buffer to read textual words into
input_buffer: resb INPUT_BUFFER_SIZE

section .data

last_word_ptr: dq _last_word

;; Stores the data stack base. It is used by the word `.s` to display the
;; content of the stack.
;;                    .
;;                    .
;;                    .
;; stack_base --> +--------+
;;                |   1    |
;;                +--------+
;;                |   2    |
;;                +--------+
;;                |   3    |
;;  rsp --------> +--------+
;;                    .
;;                    .
;;                    .
stack_base: dq 0

section .rodata

;; The structure if an error message when we encounter that some word is
;; undefined is like this: "Error: THING is undefined".
undefined_word_error: db "Error: ", 0
undefined_word_undef: db " is undefined", 10, 0

;; Error message when the Paramater Stack is empty.
empty_stack_error: db "Error: stack is empty", 10, 0

prompt_string: db ">>> ", 0

%endif                          ; MACFORTH_MEM_INC_
