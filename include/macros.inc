%ifndef MACFORTH_MACROS_INC_
%define MACFORTH_MACROS_INC_

%define concat(x,y) x %+ y

;;  Mnemonic names for a word address (precisely the address of its header
;;  field), its Code Field Address amd its Code Address.
;;  See below for the description of these fields.
%define head_field_addr(w) concat(_head_field_addr_, w)
%define code_field_addr(w) concat(_code_field_addr_, w)
%define code_addr(w) concat(_code_addr_, w)

;; _last_word is the address of the last word in the dictionary.
%define _last_word 0

;; Macro
;; -----
;; native %1, %2, %3 -> a native word
;;
;; Arguments
;; ---------
;; %1: a word name (e.g., '+', '-', '>', 'dup').
;; %2: A part of word label. This should be unique for each word defined.
;;     The final label for the word is _hfa_[%2].
;; %3: Flags (e.g., immidiate flag for IMMIDIATE words).
;;
;; Description
;; -----------
;; Helper macro to append a native word to the dictionary.
;; Picture of a typical native word (lowest address on the top):
;;                         .   .<--+
;;                         .   .   |
;;                         .   .   |
;; Header Field Address -> +---+   |
;; (Word Address)          |   |   |
;;                         |   |   |
;;                         |   |   |
;;                         | *-----+  Address of previous word (8 bytes).
;;                         |   |      (to be precise, it is the address of
;;                         |   |      previous word header field).
;;                         |   |
;;                         |   |
;;                         +---+
;;                         | 0 |      Zero (1 byte).
;;                         +---+
;;                         | d |
;;                         | u |      Word's name (%1)
;;                         | p |
;;                         +---+
;;                         | 0 |      Null-terminator (1 byte).
;;                         +---+
;;                         | 0 |      Flags (%3, 1 byte).
;; Code Field Address ---> +---+
;;                         |   |
;;                         |   |
;;                         |   |
;;                         | *-----+  Code Address (CA, 8 bytes): the
;;                         |   |   |  address of assembly implementation.
;;                         |   |   |
;;                         |   |   |
;;                         |   |   |
;; Code Address ---------> +---+<--+
;;                         |   |
;;                         .   .
;;                         .   .      Assembly implementation.
;;                         .   .
;;                         |   |
;;                         +---+
%macro native 3
    section .data
    head_field_addr(%2) : dq _last_word
    db 0
    db %1, 0
    db %3
    code_field_addr(%2) : dq code_addr(%2)

    ; Reset last word pointer to point to this word
    %define _last_word head_field_addr(%2)

    section .text
    code_addr(%2) :
%endmacro

;; native overloading for convenient (as most words will not use flags).
%macro native 2
    native %1, %2, 0
%endmacro

;; The struture of a colon word (e.g., : square dup * ;) is mostly the
;; same as that of a native word except:
;;
;; - The Code Address (8 consecutive bytes starting at the Code Field
;;   Address) is always the address of the same assembly implementation
;;   for all colon words (the so called DOCOLON or ENTER).
;;
;; - Right after the Code Field Address is a number of consecutive cells
;;   ( 8 bytes each) - these are called Paramater Field. For example, with
;;   the square colon word defined as above, its paramater field is:
;;   code_field_addr(dup), code_field_addr(*), code_field_addr(exit)
;;   <----- 8 ---------->  <-------8-------->  <--------8---------->
;;   Note that, each cell in the paramater field stores the Code Field
;;   Address (the location in memory of a word's code field) NOT the Code
;;   Address itself!
%macro colon 3
    section .data
    head_field_addr(%2) : dq _last_word
    db 0
    db %1, 0
    db %3
    code_field_addr(%2): dq code_addr(docolon)

    ; Reset last word pointer to point to this word
    %define _last_word head_field_addr(%2)
%endmacro

%macro colon 2
    colon %1, %2, 0
%endmacro

;; Helper macro to push data onto the Return Stack.
%macro rpush 1
    sub rstack, 8
    mov qword [rstack], %1
%endmacro

;; Helper macro to pop data off the Return Stack.
%macro rpop 1
    mov %1, qword [rstack]
    add rstack, 8
%endmacro

;; Helper macro to push an absolute, 32-bit address onto the Stack.
;; The reason for this is that Mach-O 64-bit format does not support
;; 32-bit absolute addresses. See [1] for more discustion about this.
;; Note that: push_addr will change rax(FIXME: do we need to save rax and
;; restore it after push?).
;;
;; [1] - https://stackoverflow.com/questions/13091987/
;; x64-nasm-pushing-memory-addresses-onto-the-stack-call-function
%macro push_addr 1
    lea rax, [rel %1]
    push rax
%endmacro

%endif                          ; MACFORTH_MACROS_INC_
