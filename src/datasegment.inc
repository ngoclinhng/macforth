%ifndef MACFORTH_DATASEGMENT_INC_
%define MACFORTH_DATASEGMENT_INC_

;; Macforth's Data Segment
;;
;; IMPORTANT
;; ---------
;; This file should only be included after built-in wordlist, so that the
;; `latest` points to the correct last word in the built-in wordlist.

section .bss

;; Return Stack.
;; ------------
;; We pre-allocate RSTACK_SIZE * 8 bytes for the return stack, which mean
;; it can store up to RSTACK_SIZE addresses.
;;
;;     lowest adress ------------------------------> highest address
;;     +-------------------------..............--------------------+
;;     +                  RSTACK_SIZE * 8 bytes                    +
;;     +-------------------------..............--------------------+
;;     ^                                                           ^
;;     |                                                           |
;; rstack_base                                                 rstack_top
alignb RSTACK_SIZE * 8
rstack_base: resq RSTACK_SIZE
rstack_top:

;; Data Space
;; ----------
;; This segment of memory is used to store user data including user-defined
;; words, variables, constants, etc...It is manages by the variable HERE
;; (the so-called data-space pointer) - which points to the next available
;; cell in this segment.
alignb DATA_SPACE_SIZE * 8
data_space: resq DATA_SPACE_SIZE

;; Variables
;; ---------
;; This section defines various variable used in Macforth.
section .data

align 8

;; Stores the address of the last word in our wordlist (to be precise, the
;; address of the last word's Header Field).
;; The corresponding word is LATEST.
latest: dq _link

;; Stores the current state of a program: 0 if interpreting, 1 if compiling.
;; The corresponding word is STATE.
state: dq 0

;; Base for reading and writing numbers. The value of base must be ranging
;; from 2 (binary) up to 36 (inclusive).
;; The corresponding word is BASE.
base: dq 10

;; Stores the base of the the data stack.
;; The corresponding word is S0.
stack_base: dq 0

;; Stores the address of the next available cell in the data space segment.
;; The corresponding word is HERE (which returns [here]).
here: dq data_space
%endif
