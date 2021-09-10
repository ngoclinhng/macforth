%include "constants.inc"

;; Export symbols
global strlen
global prints
global printn
global printc
global printu
global printi
global readc
global readw
global parseu
global parsei
global strequ
global strcpy
global exit

;; whitespace characters: space, newline, carriage return, horizontal tab
%define SP_CHAR_CODE 32
%define NL_CHAR_CODE 10
%define CR_CHAR_CODE 13
%define HT_CHAR_CODE 9

section .text

;; strlen(rdi) -> rax.
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;;
;; Description
;; -----------
;; Takes as argument a pointer to a null-terminated string, computes its
;; length, and returns the result in rax.
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0     ; Is next character a null-terminator?
    je .end
    inc rax
    jmp .loop
.end:
    ret

;; prints(rdi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;;
;; Description
;; -----------
;; Takes as argument a pointer to a null-terminated string, and outputs it
;; to stdout.
prints:
    push rdi
    call strlen
    pop rsi                     ; source
    mov rdx, rax                ; num bytes to be written

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT_FILENO      ; destination
    syscall

    ret

;; printn() -> stdout.
;;
;; Arguments
;; ----------
;; This function does not take any arguments.
;;
;; Description
;; -----------
;; Outputs newline character to stdout.
;;
;; Implementation notes
;; --------------------
;; This function doesn't actually do anything except write the newline
;; character into rdi, which then gets passed into `printc` right below it.
printn:
    mov rdi, 10

;; printc(rdi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: single character code
;;
;; Description
;; -----------
;; Takes as argument a single character code and outputs it to stdout.
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

;; printu(rdi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: 8 bytes represents an unsigned integer.
;;
;; Description
;; -----------
;; Takes as input an unsigned integer and outputs it to stdout.
;;
;; Implementation notes
;; --------------------
;; Let's take a look at an application of `printu`:
;;
;;   mov rdi, 123
;;   call printu
;;
;; We would expect the string '123' to be printed to stdout. But how are
;; we about to convert 64 bits of 0s and 1s in rdi to the string '123'?
;;
;; Perform unsgined division whatever shit in rdi by 10. The quotient is
;; the bit pattern for the unsigned integer 12, and the remainder is the
;; bit pattern for the unsgined integer 3. In general, the remainder is the
;; 4-bit pattern (all other leading bits are 0) for one of the 10 digits
;; (0-9), and by xoring it with 1 byte 0x30, we will get the ASCII character
;; representing that digit. Repeat this procudure until the quotient is 0,
;; we would get all the wanted digits.
;;
;; We also need to store each byte generated (at each iteration) on the
;; stack. But how much memory (on the stack) should we allocate? Well, the
;; biggest 8-byte unsigned integer corresponding to all bits are turned on
;; in rdi, which is the number 2^64-1 = 1.844674407E19 (20 digits) in
;; decimal format. So, we need to allocate at least 20 bytes on the stack.
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

;; printi(rdi) -> stdout.
;;
;; Arguments
;; ----------
;; rdi: 8-byte, signed integer
;;
;; Description
;; -----------
;; Takes as input 8-byte, signed integer, and outputs it to stdout.
printi:
    test rdi, rdi
    jns printu

    push rdi
    mov rdi, '-'
    call printc
    pop rdi

    neg rdi
    jmp printu

;; readc() -> rax.
;;
;; Arguments:
;; ----------
;; This function does not take any arguments.
;;
;; Description
;; -----------
;; Reads next character from stdin and stores in in rax. If the end of
;; input stream occurs, rax will hold zero instead.
readc:
    push 0

    mov rax, SYSCALL_READ
    mov rdi, STDIN_FILENO       ; source
    mov rsi, rsp                ; buffer
    mov rdx, 1                  ; read 1 byte
    syscall

    pop rax
    ret

;; readw(rdi, rsi) -> (rax, rdx).
;;
;; Arguments
;; ---------
;; rdi: the buffer's address.
;; rsi: the buffer's size.
;;
;; Description
;; -----------
;; Reads at most (size - 1) consecutive, non-whitespace characters from
;; stdin and stores the null-terminated string into the buffer (whose
;; address is stored in rdi). When this function returns, rax will hold
;; the buffer's address (which is also the address of the null-terminated
;; string has just been read) and rdx will hold the string's length.
;; If the word is too big for the specified buffer size, rax will hold zero
;; instead.
;; Note that: readw will skip all leading whitespaces until it encounters a
;; non-whitespace character or the end of input stream.
readw:
    ; r14 will store the index into the
    ; buffer of next character, and r15
    ; will store the maximum number of
    ; characters allowed (equal to buffer's size - 1).
    push r14
    push r15

    ; Initialize index and maximum number
    ; of characters allowed.
    xor r14, r14
    mov r15, rsi
    dec r15

.read_first_char:
    ; Read next character from stdin,
    ; and the store result in rax.
    push rdi
    call readc
    pop rdi

    ; Skip this character if it is one
    ; of the whitespace characters.
    cmp al, SP_CHAR_CODE
    je .read_first_char
    cmp al, NL_CHAR_CODE
    je .read_first_char
    cmp al, CR_CHAR_CODE
    je .read_first_char
    cmp al, HT_CHAR_CODE
    je .read_first_char

    ; If we reach the end of input stream,
    ; goto .end
    test al, al
    jz .end

.loop:
    ; store previously read character
    ; at desired index.
    mov byte [rdi + r14], al
    inc r14

    ; Read next character
    push rdi
    call readc
    pop rdi

    ; If it is one of the whitespace characters,
    ; break out of the loop, and goto .end
    cmp al, SP_CHAR_CODE
    je .end
    cmp al, NL_CHAR_CODE
    je .end
    cmp al, CR_CHAR_CODE
    je .end
    cmp al, HT_CHAR_CODE
    je .end

    ; If the end of input stream occurs,
    ; break out of the loop, and goto .end
    test al, al
    jz .end

    ; al is a `normal` character but we
    ; have just reached the maximum number
    ; of characters allowed. If this is
    ; the case, goto .error
    cmp r14, r15
    je .error

    ; Otherwise, loop back.
    jmp .loop

.error:
    xor rax, rax
    pop r15
    pop r14
    ret

.end:
    ; write null-terminator
    mov byte [rdi + r14], 0

    ; return values
    mov rax, rdi
    mov rdx, r14

    ; restore callee-saved registers
    pop r15
    pop r14

    ret

;; parseu(rdi) -> (rax, rdx).
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string. The input string must starts
;; with a digit character (0-9).
;;
;; Description
;; -----------
;; Parses an unsigned (8-byte) integer from the start of the given
;; null-terminated string, and returns the parsed number in rax and its
;; digits count in rdx.
;; Note that if your input string is something like '0123', the integer in
;; rax will be 123, and rdx will be 4. (FIXME)
parseu:
    ; The final number will be stored
    ; in rax. rcx is used to keep track
    ; of digits count.
    xor rax, rax
    xor rcx, rcx

    ; Each time a next digit is read,
    ; we update rax as follows:
    ; rax = rax * 10 + `that next digit`.
    mov r8, 10

.loop:
    ; read next digit, we have to
    ; `move zero-extended` here.
    movzx r9, byte [rdi + rcx]

    ; since the byte range for digit
    ; 0-9 is 0x30-0x39 (see man ascii),
    ; if this digit is bellow or above this
    ; range, goto .end
    cmp r9b, 0x30
    jb .end
    cmp r9b, 0x39
    ja .end

    ; Before updating rax with this
    ; new digit, we need to convert
    ; it to the byte value which
    ; evaluates to the digit itself.
    and r9b, 0x0f

    ; update rax with new digit
    ; rax = rax * 10 + r9b
    mul r8
    add rax, r9

    ; increment digits count, and
    ; loop back.
    inc rcx
    jmp .loop

.end:
    mov rdx, rcx
    ret

;; parsei(rdi) -> (rax, rdx).
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string. The input string must
;;      starts with an digit (0-9) or one of these characters ('+', '-')
;;      immediately followed by a digit (spaces between aren't allowed).
;;
;; Description
;; -----------
;; Parses an 8-byte, signed integer from the start of the specified input
;; string, and returns the parsed number in rax; its digits count
;; (plus 1 for the minus sign if any) in rdx.
;;
;; See parseu for more details.
parsei:
    ; Read first character
    mov al, byte [rdi]

    ; Is it '-'?
    cmp al, '-'
    jz .signed

    ; Is it '+'?
    cmp al, '+'
    jz .unsigned

    ; If the first character is neither
    ; '+' nor '-', hand over to `parseu`.
    jmp parseu

.signed:
    inc rdi
    call parseu

    test rdx, rdx
    jz .error

    neg rax
    inc rdx
    ret
.unsigned:
    ; we don't count the plus sign '+'.
    inc rdi
    jmp parseu

.error:
    xor rax, rax
    ret

;; strequ(rdi, rsi) -> rax (either 0 or 1).
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;; rsi: a pointer to a null-terminated string.
;;
;; Description
;; -----------
;; Takes as inputs two pointers to two null-terminated strings, compares
;; them (character by character), and returns 1 if they are equal,
;; otherwise returns 0.
;;
;; Two null-terminated strings are considered equal if and only if they
;; are of the same length (having exactly the same number of characters),
;; and the corresponding characters are identical.
strequ:
    ; Compare next two characters, and
    ; if they're not equal, go to .no
    mov al, byte [rdi]
    cmp al, byte [rsi]
    jne .no

    ; They are both equal to null-terminator,
    ; go to .yes
    test al, al
    jz .yes

    ; Otherwise, advance two pointers
    ; and loop back.
    inc rdi
    inc rsi
    jmp strequ

.yes:
    mov rax, 1
    ret

.no:
    xor rax, rax
    ret

;; strcpy(rdi, rsi, rdx) -> rax.
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;; rsi: buffer address.
;; rdx: buffer size.
;;
;; Description
;; -----------
;; Takes as inputs a pointer to a null-terminated string, a buffer address,
;; and a buffer size, copies the string into the buffer, and returns the
;; buffer address in rax.
;; If the given string is too long for the specified buffer, 0 is returned
;; instead.
strcpy:
    ; rcx will hold the index into the
    ; buffer of the next character, rdx
    ; is the maximum number of characters
    ; allowed (exclude null-terminator).
    xor rcx, rcx
    dec rdx

.loop:
    ; Read next character from the source string,
    ; and if it is a null-terminator, go to .end
    mov al, byte [rdi + rcx]
    test al, al
    jz .end

    ; Maximum number of characters has been reached,
    ; but next character is not a null-terminator,
    ; go to .error
    cmp rcx, rdx
    je .error

    ; Otherwise, write next character into the
    ; destination, advance index, and loop back.
    mov [rsi + rcx], al
    inc rcx
    jmp .loop

.error:
    xor rax, rax
    ret

.end:
    mov byte [rsi + rcx], 0
    mov rax, rsi
    ret

;; exit(rdi) -> noreturn
;;
;; Arguments
;; ---------
;; rdi: the exit status code.
;;
;; Description
;; -----------
;; Terminates the current process with the given exit status code
;; (given in rdi).
exit:
    mov rax, SYSCALL_EXIT
    syscall
