%ifndef MACFORTH_MEM_INC_
%define MACFORTH_MEM_INC_

;; IMPORTANT: this file should only be included after the dictionary!
;; (so that last_word_ptr points to the correct last word in the dictionary).

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

;; Changes to 1 if compiling, 0 by default.
state_ptr: resq 1

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

%endif                          ; MACFORTH_MEM_INC_
