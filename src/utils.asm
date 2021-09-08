%include "constants.inc"

;; Export symbols
global strlen
global exit

section .text

;; Function: strlen(rdi) -> rax.
;;
;; Arguments:
;;   rdi: a pointer to a null-terminated string.
;;
;; Description: Takes as argument a pointer to a null-terminated string,
;;              computes its length, and returns the result in rax.
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0     ; Is next character a null-terminator?
    je .end
    inc rax
    jmp .loop
.end:
    ret

;; Function: exit(rdi) ->
;;
;; Arguments:
;;   rdi: the exit status code.
;;
;; Description: Terminates the current process with the given exit status
;;              code (given in rdi).
exit:
    mov rax, SYSCALL_EXIT
    syscall
