global _main

%include "macforth.inc"
%include "words.inc"
%include "mem.inc"

section .text
_main:
    jmp code_addr(init)
