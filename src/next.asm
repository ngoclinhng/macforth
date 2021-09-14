%include "regs.inc"

global next

section .text
;; Forth inner interpreter.
;;
;; At every moment, pc points to a cell in memory - which stores the address
;; of a word's Code Field (Code Field Address). The interpreter fetches
;; that address into the Working register (w), advances the pc by 8 (to
;; point to another CFA of another word in the thread), and then jumps to
;; the address stored at the memory location designated by the content of W.
;; This address (so called Code Address or CA for short) is the location
;; in memory of an assembly subroutine which performs the word.
;;
;; ...+----------------+...
;; ...+      CFA       +
;; ...+-------|--------+...
;;    ^       |
;;    |       |
;;    pc      |        +----------------+
;;            |        +      CA        +
;;            +------->+-------|--------+
;;                             |
;;                             |        +-----..............----+
;;                             |        +  Assembly Subroutine  +
;;                             +------->+-----..............----+
next:
    mov w, [pc]
    add pc, 8
    jmp [w]
