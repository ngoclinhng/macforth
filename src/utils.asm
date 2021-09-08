%include "constants.inc"

;; Export symbols
global strlen
global prints
global printn
global printc
global printu
global printi
global readc
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

;; Function: printu(rdi) -> stdout.
;;
;; Arguments:
;;   rdi: 8 bytes represents an unsigned integer.
;;
;; Description: Takes as input an unsigned integer and outputs it to stdout.
;;
;; How: Let's take a look at an application of `printu`:
;;
;;        mov rdi, 123
;;        call printu
;;
;;      We would expect the string '123' to be printed to stdout. But how
;;      are we about to convert 64 bits of 0s and 1s in rdi to the string
;;      '123'?
;;
;;      Perform unsgined division whatever shit in rdi by 10. The quotient
;;      is the bit pattern for the unsigned integer 12, and the remainder
;;      is the bit pattern for the unsgined integer 3. In general, the
;;      remainder is the 4-bit pattern (all other leading bits are 0) for
;;      one of the 10 digits (0-9), and by xoring it with 1 byte 0x30, we
;;      will get the ASCII character representing that digit. Repeat this
;;      procudure until the quotient is 0, we would get all the wanted
;;      digits.
;;
;;      We also need to store each byte generated (at each iteration) on
;;      the stack. But how much memory (on the stack) should we allocate?
;;      Well, the biggest 8-byte unsigned integer corresponding to all bits
;;      are turned on in rdi, which is the number 2^64-1 = 1.844674407E19
;;      (20 digits) in decimal format. So, we need to allocate at least 20
;;      bytes on the stack.
printu:
    mov rax, rdi                ; needed for DIV instruction
    mov rdi, rsp                ; at the end, rdi points to digits string

    push 0                      ; 8 bytes, all zeros
    sub rsp, 16                 ; 16 more bytes

    dec rdi                     ; so that digits string is null-terminated
    mov r8, 10                  ; needed for DIV instruction

.loop:
    xor rdx, rdx                ; unsigned divide rdx:rax by
    div r8                      ; r8

    or dl, 0x30                 ; rdx is remainder, rax is quotient
    dec rdi
    mov [rdi], dl

    test rax, rax               ; is quotient zero?
    jnz .loop

    call prints
    add rsp, 24                 ; restore rsp
    ret

;; Function: printi(rdi) -> stdout.
;;
;; Arguments:
;;   rdi: 8-byte, signed integer
;;
;; Description: Takes as input 8-byte, signed integer, and outputs it
;;              to stdout.
printi:
    test rdi, rdi
    jns printu

    push rdi
    mov rdi, '-'
    call printc
    pop rdi

    neg rdi
    jmp printu

;; Function: readc(stdin) -> rax.
;; Description: Reads next character from stdin and stores in in rax. If
;;              the end of input stream occurs, rax will hold zero instead.
readc:
    push 0

    mov rax, SYSCALL_READ
    mov rdi, STDIN_FILENO       ; source
    mov rsi, rsp                ; buffer
    mov rdx, 1                  ; read 1 byte
    syscall

    pop rax
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
