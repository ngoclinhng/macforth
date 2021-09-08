%include "constants.inc"

;; Export symbols
global strlen
global prints
global printn
global printc
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

;; Function: prints(rdi) -> stdout.
;;
;; Arguments:
;;   rdi: a pointer to a null-terminated string.
;;
;; Description: Takes as argument a pointer to a null-terminated string,
;;              and outputs it to stdout.
prints:
    push rdi
    call strlen
    pop rsi                     ; source
    mov rdx, rax                ; num bytes to be written

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT_FILENO      ; destination
    syscall

    ret

;; Function: printn() -> stdout.
;; Description: outputs newline character to stdout.
;; Note that: this function doesn't actually do anything except write
;; the newline character into rdi, which then gets passed into `printc`
;; right below it.
printn:
    mov rdi, 10

;; Function: printc(rdi) -> stdout.
;;
;; Arguments:
;;   rdi: single character code
;;
;; Description: Takes as argument a single character code and outputs it
;;              to stdout.
printc:
    ; FIXME: the following implementation implicitly assumes that the
    ; target machine is Little Endian, so that after pushing rdi on top
    ; of the stack, rsp is the address of the least significant byte
    ; in rdi (dl).
    push rdi
    mov rdi, rsp
    call prints
    pop rdi
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
