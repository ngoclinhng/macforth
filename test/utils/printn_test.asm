%include "utils.inc"

global _main

section .text
_main:
    call printn
    xor rdi, rdi
    call exit
