%ifndef MACFORTH_MEM_INC_
%define MACFORTH_MEM_INC_

;; IMPORTANT: this file should only be included after the dictionary!

section .bss

;; Return Stack.
;; We pre-allocate 8 Kb (1024 * 8 bytes) for the return stack (which mean
;; it can store at most 1024 addresses!).
;;
;; lowest adress --------------------------> highest address
;; +-----------..............------------------+-----------+
;; +                1023 bytes                 +  8 bytes  +
;; +-----------..............------------------+-----------+
;;                                             ^
;;                                             |
;;                                          rp_start
resq 1023
rstack_start: resq 1

;; Input Buffer: buffer to read textual words into
input_buffer: resb INPUT_BUFFER_SIZE

;; Data for words (64 Kb)
user_dict: resq 65536

;; Global data for user
user_memm: resq 65536

;; Changes to 1 if compiling, 0 by default.
state_ptr: resq 1

section .data
last_word_ptr: dq _last_word
user_dict_ptr: dq user_dict
user_memm_ptr: dq user_memm

section .rodata
no_such_word_msg: db ": no such word", 10, 0

%endif                          ; MACFORTH_MEM_INC_
