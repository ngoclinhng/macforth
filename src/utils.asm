%include "macros.inc"

;; Export symbols
;; ---------------

global cstring_length
global print_cstring
global print_string
global print_char
global print_uint
global print_int
global read_char
global parse_name
global string_case_compare
global string_copy
global string_to_int

global DOCOL
global DOVAR

global input_buffer
global input_buffer_offset
global input_buffer_length

section .text

;; cstring_length(rdi) -> rax.
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;;
;; Description
;; -----------
;; Takes as argument a pointer to a null-terminated string, computes its
;; length, and returns the result in rax.
cstring_length:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0     ; Is next character a null-terminator?
    je .end
    inc rax
    jmp .loop
.end:
    ret

;; print_cstring(rdi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: a pointer to a null-terminated string.
;;
;; Description
;; -----------
;; Takes as argument a pointer to a null-terminated string, and outputs it
;; to stdout.
print_cstring:
    push rdi
    call cstring_length
    pop rsi                     ; source
    mov rdx, rax                ; num bytes to be written

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT_FILENO      ; destination
    syscall

    ret

;; print_string(rdi, rsi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: the address of a string (not neccessarily null-terminated).
;; rsi: the length of the above string (its number of characters).
;;
;; Description
;; -----------
;; Takes as arguments an address of a string and its character count, and
;; prints it out to stdout.
print_string:
    mov rdx, rsi                ; number of bytes
    mov rsi, rdi                ; source
    mov rax, SYSCALL_WRITE      ; write syscall
    mov rdi, STDOUT_FILENO      ; destination
    syscall
    ret

;; print_char(rdi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: A single character code.
;;
;; Description
;; -----------
;; Takes as argument a single character code and outputs it to stdout. If
;; rdi is not a character code, its lowest byte (dl) will be printed out
;; instead!
print_char:
    ; FIXME: the following implementation implicitly assumes that the
    ; target machine is Little Endian, so that after pushing rdi on top
    ; of the stack, rsp is the address of the least significant byte
    ; in rdi (dl).
    push rdi
    mov rsi, rsp                ; source

    mov rax, SYSCALL_WRITE
    mov rdi, STDOUT_FILENO      ; destination
    mov rdx, 1                  ; 1 byte
    syscall

    pop rdi
    ret

;; print_uint(rdi, rsi) -> stdout.
;;
;; Arguments
;; ---------
;; rdi: 8 bytes represents an unsigned integer.
;; rsi: base, ranging from 2 up to 36 (inclusive).
;;
;; Description
;; -----------
;; Converts the unsgined integer to base (hex, decimal, binary, etc...),
;; and print_cstring it out to stdout.
;;
;; Rule of conversion:
;;
;; 1. Digits with decimal values ranging from 0 to 9 correspond to
;;    characters '0' to '9', respectively.
;;
;; 2. Digits with decimal values ranging from 10 up to 35 (inclusive)
;;    correspond to characters 'A' to 'Z', respectively.
;;
;; 3. If x_n,x_(n-1),...,x_0 is the result of the conversion, the decimal
;;    value of the original (unsigned) number is:
;;    x_n * base^n + x_(n-1) * base^(n-1) + ... + x_0
print_uint:
    ; Setup for div instruction
    mov rax, rdi
    mov r8, rsi

    ; Address to write next digit. At the end, rdi points to the digits
    ; string.
    mov rdi, rsp


    ; Allocate space on the stack to store digits. How many bytes do we
    ; need to allocate? Well, the biggest 8-byte unsigned integer
    ; corresponds to all bits are turned on, so, if the base is 2 (lowest
    ; base allowed) we need 64 bytes to hold all digits for this number.
    ; In general, we'll need at most 64 bytes to hold the digits string.
    push 0                      ; 8 bytes, all zeros
    sub rsp, 64                 ; 64 more bytes
    dec rdi                     ; so that digits string is null-terminated
.loop:
    xor rdx, rdx                ; unsigned divide rdx:rax by
    div r8                      ; r8

    ; rdx is the remainder. Since our base ranges from 2 up to 36, and
    ; 0 <= remainder < base, only the lowest byte (dl) of rdx matters (all
    ; leading bytes are zero). If the value of the digit stored in dl is
    ; in the range 0 to 9, we "or" it with the byte `0x30` to get its
    ; character representation. Otherwise, we add it with the byte `0x37`
    ; to convert it to the corresponding character.
    cmp dl, 10
    jae .ae_ten
    or dl, 0x30
    jmp .continue
.ae_ten:
    add dl, 0x37
.continue
    ; Write the character.
    dec rdi
    mov [rdi], dl

    ; rax is the quotient. If the quotient is not zero, we'll loop back.
    ; Otherwise, we're done.
    test rax, rax
    jnz .loop

    ; If the base is 16, we need to append '0x' to the digits string.
    cmp r8, 16
    je .append_hex

    ; Else if the base is 2, append '0b'
    cmp r8, 2
    je .append_bin

    ; Else if the base is 8, append '0o'
    cmp r8, 8
    je .append_oct

    ; For other format, we leave the number as-is.
    jmp .end
.append_hex:
    sub rdi, 2
    mov word [rdi], 0x7830
    jmp .end
.append_bin:
    sub rdi, 2
    mov word [rdi], 0x6230
    jmp .end
.append_oct:
    sub rdi, 2
    mov word [rdi], 0x6f30
.end:
    call print_cstring           ; Print digits string to stdout
    add rsp, 72                 ; Restore rsp
    ret

;; print_int(rdi, rsi) -> stdout.
;; Same as print_uint, except this function deals with signed integer.
print_int:
    test rdi, rdi
    jns print_uint

    push rdi
    push rsi
    mov rdi, '-'
    call print_char
    pop rsi
    pop rdi

    neg rdi
    jmp print_uint

;; read_char(stdin) -> rax.
;;
;; Reads next byte (at the index input_buffer_offset) from the input buffer
;; and returns it in rax.
;;
;; If the input buffer is exhausted (when input_buffer_offset equals to
;; input_buffer_length), read_char will refill it automatically with more
;; characters read from stdin, set input_buffer_length to the number of bytes
;; that has been read from stdin, reset input_buffer_offset to zero, and go
;; back to read next byte (as if the input buffer had never been exhausted
;; in the first place).
;;
;; During the process of reading more characters from stdin, if an error or
;; end-of-file is encountered, read_char will terminate the program!
;; (with the exit status of 0).
read_char:
    ; Read the offset into rcx and compare it with the length of the input
    ; buffer. If the offset is either equal or "above" the length, we know
    ; that we have just exhausted the input buffer.
    mov rcx, riprel(input_buffer_offset)
    cmp rcx, riprel(input_buffer_length)
    jae .read_more

    ; Compute the address of next char.
    lea rax, riprel(input_buffer)
    add rax, rcx

    ; Read next char into rax.
    movzx rax, byte [rax]

    ; Increment the offset and return.
    inc rcx
    mov riprel(input_buffer_offset), rcx
    ret
.read_more:
    ; Read at most INPUT_BUFFER_SIZE bytes from stdin into the input buffer
    mov rax, SYSCALL_READ
    mov rdi, STDIN_FILENO
    lea rsi, riprel(input_buffer)
    mov rdx, INPUT_BUFFER_SIZE
    syscall

    ; If successful, rax = number of bytes actually read. Otherwise,
    ; rax = 0 (if end-of-file) or -1 (if error).
    test rax, rax
    jle .exit

    ; Reset offset and length and go back to read as normally.
    mov riprel(input_buffer_length), rax
    mov qword riprel(input_buffer_offset), 0
    jmp read_char
.exit:
    xor rdi, rdi
    mov rax, SYSCALL_EXIT
    syscall

;; parse_name(stdin) -> (rax, rdx)
;;
;; parse_name first skips leading blanks (any character that has hex value
;; less than or equal to 0x20 including spaces, tabs, newlines, and so on).
;; Then it repeatedly calls read_char until either a blank is found or end
;; of the input buffer. At this point, it returns the address (within the
;; input buffer) of the parsed string in rax, and its length in rdx.
parse_name:
    call read_char              ; keep looking for the first non-blank
    cmp al, SP_CHAR             ; is is a blank?
    jbe parse_name              ; if so, keep looking

    push r14                    ; r14 is a callee-saved register
    push r15                    ; so is r15

    xor r15, r15                ; length

    ; The final address of the parsed string.
    lea r14, riprel(input_buffer)
    mov rax, riprel(input_buffer_offset)
    add r14, rax
    dec r14
.loop:
    inc r15

    ; When we hit the end of the input buffer, next call to read_char will
    ; refill this buffer with new contents and completedly overwrite the
    ; partially parsed string.
    mov rax, riprel(input_buffer_offset)
    cmp rax, riprel(input_buffer_length)
    jae .end

    ; Keep reading until a blank is found.
    call read_char
    cmp al, SP_CHAR
    ja .loop
.end:
    mov rax, r14
    mov rdx, r15
    pop r15
    pop r14
    ret

;; bin_to_uint(rdi, rsi) -> (rax, rdx)
;; Convert the binary string specified by rdi (address) and length (rsi)
;; into an 8-byte unsigned integer (stored in rax). If the convertion
;; succeeds rdx will be -1, otherwise it'll be 0.
;; A valid input string must be prefixed with '0b', for example 0b1010(10).
bin_to_uint:
    xor rax, rax                ; will hold the final result

    cmp rsi, 2                  ; is length > 2 ?
    jle .error                  ; if not, input string is invalid

    cmp word [rdi], 0x6230      ; starts with '0b' ?
    jne .error                  ; if not, input string is also invalid

    add rdi, 2
    sub rsi, 2
    mov r8, 2                   ; binary radix
.loop:
    test rsi, rsi               ; end of string yet?
    jz .end

    movzx r9, byte [rdi]        ; read next character

    cmp r9b, '0'                ; since this is a binary string, we would
    jb .error                   ; expect its characters to be either '0'
    cmp r9b, '1'                ; or '1'. If one character lies outside of
    ja .error                   ; this range, it is invalid.

    and r9b, 0x0f               ; convert to the corresponding decimal

    xor rdx, rdx                ; multiple rax by r8 and store the result
    mul r8                      ; in rax (ignore overflow in rdx)
    add rax, r9                 ; add digit to rax

    inc rdi                     ; advance to next char
    dec rsi                     ; decrement remaining
    jmp .loop
.error:
    xor rdx, rdx                ; 0 flag indicates error
    ret
.end:
    mov rdx, -1                 ; -1 flag indicates success
    ret

;; oct_to_uint(rdi, rsi) -> (rax, rdx)
;; Convert the octal string specified by rdi (address) and length (rsi)
;; into an 8-byte unsigned integer (stored in rax). If the convertion
;; succeeds rdx will be -1, otherwise it'll be 0.
;; A valid input string must be prefixed with '0o', for example 0o012(10).
oct_to_uint:
    xor rax, rax                ; will hold the result

    cmp rsi, 2                  ; is length > 2 ?
    jle .error                  ; if not, input string is invalid

    cmp word [rdi], 0x6f30      ; starts with '0o'?
    jne .error                  ; if not, input string is also invalid

    add rdi, 2
    sub rsi, 2
    mov r8, 8                   ; octal radix
.loop:
    test rsi, rsi               ; end of the input string yet?
    jz .end

    movzx r9, byte [rdi]        ; read next character

    cmp r9b, '0'                ; since this is an octal string, we would
    jb .error                   ; expect all of its characters to be in
    cmp r9b, '7'                ; the range '0' - '7'. If one lies outside
    ja .error                   ; of this range, it is invalid.

    and r9b, 0x0f               ; convert char to the corresponding decimal

    xor rdx, rdx                ; multiply rax by r8, and store the result
    mul r8                      ; in rax (ignore overflow)
    add rax, r9                 ; add digit to rax

    inc rdi                     ; advance to next char
    dec rsi                     ; decrement remaining
    jmp .loop
.error:
    xor rdx, rdx
    ret
.end:
    mov rdx, -1
    ret

;; dec_to_uint(rdi, rsi) -> (rax, rdx)
;; Convert the decimal string specified by rdi (address) and length (rsi)
;; into an 8-byte unsigned integer (stored in rax). If the convertion
;; succeeds rdx will be -1, otherwise it'll be 0.
dec_to_uint:
    xor rax, rax                ; will hold the final result
    mov r8, 10                  ; decimal radix
.loop:
    test rsi, rsi
    jz .end

    movzx r9, byte [rdi]        ; read next char

    cmp r9b, '0'                ; since this is a decimal string, we would
    jb .error                   ; expect all of its characters to be in the
    cmp r9b, '9'                ; range '0' - '9'. If one lies outside of
    ja .error                   ; this range, it is invalid.

    and r9b, 0x0f               ; convert to corresponding decimal value

    xor rdx, rdx                ; multiply rax by r8, and store the result
    mul r8                      ; in rax (ignore overflow in rdx)
    add rax, r9                 ; add digit to rax

    inc rdi                     ; advance to next char
    dec rsi                     ; decrement remaining
    jmp .loop
.error:
    xor rdx, rdx
    ret
.end:
    mov rdx, -1
    ret

;; hex_to_uint(rdi, rsi) -> (rax, rdx)
;; Convert the hexadecimal string specified by rdi (address) and length(rsi)
;; into an 8-byte unsigned integer (stored in rax). If the convertion
;; succeeds rdx will be -1, otherwise 0.
;; A valid input string must be prefixed with '0x', for example 0xA(10).
hex_to_uint:
    xor rax, rax                ; will hold the final result

    cmp rsi, 2                  ; is length > 2 ?
    jle .error                  ; if not, input string is invalid

    cmp word [rdi], 0x7830      ; starts with '0x'?
    jne .error                  ; if not, input string is also invalid

    add rdi, 2                  ; go past the '0x' prefix
    sub rsi, 2                  ; remaining count
    mov r8, 16                  ; hexadecimal radix
.loop:
    test rsi, rsi               ; end of input string yet?
    jz .end                     ; if so, go to .end

    movzx r9, byte [rdi]        ; read next char

    cmp r9b, '0'                ; is next char below '0'?
    jb .error                   ; if so, it is invalid
    cmp r9b, '9'                ; is it below or equal '9'?
    jbe .A                      ; is so char is in the range '0' - '9'

    cmp r9b, 'A',               ; is char below 'A'?
    jb .error                   ; if so, it is invalid
    cmp r9b, 'F'                ; is it below or equal 'F'?
    jbe .B                      ; if so, it's in the range 'A' - 'F'.

    cmp r9b, 'a'                ; if char below 'a'
    jb .error                   ; if so, it is invalid
    cmp r9b, 'f'                ; is it above 'f'
    ja .error                   ; if so, it is also invalid

    sub r9b, 32                 ; convert to the corresponding uppercase
    jmp .B                      ; letter, and go to .B
.A:
    and r9b, 0x0f               ; convert to corresponding decimal value
    jmp .continue
.B:
    and r9b, 0x0f               ; convert to corresponding
    add r9b, 9                  ; decimal value (TODO: two instructions?)
.continue:
    xor rdx, rdx                ; multiple rax by r8 and store the result
    mul r8                      ; in rax (ignore overflow in rdx)
    add rax, r9                 ; add digit to rax

    inc rdi                     ; advance to next char
    dec rsi                     ; decrement remaining
    jmp .loop
.error:
    xor rdx, rdx
    ret
.end:
    mov rdx, -1
    ret

;; string_to_uint(rdi, rsi, rdx) -> (rax, rdx).
;; Convert the string specified by rdi (address) and rsi (length) into
;; an 8-byte unsigned integer (rax), using the value in rdx as the radix
;; for conversion. If the conversion succeeds, the flag rdx is set to -1,
;; otherwise rdx will be 0.
string_to_uint:
    cmp rdx, 2                  ; is binary?
    je bin_to_uint

    cmp rdx, 8                  ; is octal?
    je oct_to_uint

    cmp rdx, 10                 ; is decimal?
    je dec_to_uint

    cmp rdx, 16                 ; is hexadecimal?
    je hex_to_uint

    ; None of the above
    xor rax, rax
    xor rdx, rdx
    ret

;; string_to_int(rdi, rsi, rdx) -> (rax, rdx).
;; Convert the string specified by rdi (address) and rsi (length) into
;; an 8-byte integer (rax), using the value in rdx as the radix for
;; conversion. If the conversion fails, the flag rdx is set to 0, otherwise
;; -1.
string_to_int:
    mov al, byte [rdi]
    cmp al, '-'
    je .signed
    jmp string_to_uint
.signed:
    inc rdi
    dec rsi
    call string_to_uint
    test rdx, rdx
    jz .error
    neg rax
.error:
    ret

;; read_word(stdin) -> rax.
;;
;; read_word first skips any blanks (spaces, tabs, newlines, and so on).
;; Then it repeatedly calls read_char to read characters into an internal
;; buffer until it hits a blank. Finally it returns the address of the
;; counted string in rax:
;;
;;   <-- 1 byte -->
;;   +------------+----------......----------+
;;   |     LEN    |        CHARACTERS        |
;;   +------------+----------......----------+
;;   ^
;;   |
;;   rax
;;
;; Note that read_word has an internal buffer of size WORD_BUFFER_SIZE bytes
;; that it overwrites each time. Also notice that if the word length exceeds
;; the MAX_WORD_LENGTH value, rax will hold zero!
read_word:
    ; Save callee-saved registers.
    push r14
    push r15

    lea r14, riprel(word_buffer)
    inc r14                     ; skip first byte (used for length)
    xor r15, r15                ; r15 holds length
.first_non_blank:
    call read_char
    cmp al, START_COMMENT_CHAR  ; start of a comment?
    je .skip_comment            ; if so, skip the comment

    cmp al, SP_CHAR             ; is it a blank?
    jbe .first_non_blank        ; if so, keep looking
.loop:
    mov [r14 + r15], al         ; write char at the designed index
    inc r15                     ; advance index

    call read_char              ; read next char
    cmp al, SP_CHAR             ; is it a blank?
    jbe .end                    ; if so, we're done.

    cmp r15, MAX_WORD_LENGTH    ; overflow?
    je .overflow                ; if so, we're in trouble!
    jmp .loop                   ; NOTA? keep looping
.skip_comment:
    call read_char
    cmp al, NL_CHAR             ; end of line yet?
    jne .skip_comment           ; not yet!
    jmp .first_non_blank
.end:
    dec r14                     ; back to length's address
    mov [r14], r15b             ; write length
    mov rax, r14                ; return value

    ; Restore callee-saved registers
    pop r15
    pop r14
    ret
.overflow:
    xor rax, rax
    pop r15
    pop r14
    ret

;; tolower(rdi) -> rax.
;;
;; Arguments
;; ---------
;; rdi: A character code.
;;
;; Description
;; -----------
;; If argument is an upper-case letter, the function returns the
;; corresponding lower-case letter if there is one; otherwise, the argument
;; is returned unchanged.
tolower:
    cmp dil, 65
    jb .end
    cmp dil, 90
    ja .end
    add dil, 32
.end:
    mov rax, rdi
    ret

;; string_case_compare(rdi, rsi, rdx) -> rax (0 or 1).
;;
;; Compares character string rdi against character string rsi without
;; sensitivity to case. Both strings are assumed to be rdx bytes long.
;; Returns 1 if they are equal, 0 otherwise.
string_case_compare:
    test rdx, rdx
    jz .equal

    push rdx
    push rdi
    push rsi

    movzx rdi, byte [rdi]
    call tolower
    mov r12, rax

    mov rdi, [rsp]
    movzx rdi, byte [rdi]
    call tolower

    pop rsi
    pop rdi
    pop rdx

    cmp r12, rax
    jne .not_equal

    inc rdi
    inc rsi
    dec rdx
    jmp string_case_compare
.equal:
    mov rax, 1
    ret
.not_equal:
    xor rax, rax
    ret

;; string_copy(rdi, rsi, rdx) -> void.
;;
;; Copies rdx bytes (characters) from the memory location designated by rsi
;; (source) to the memory location designated by rdi (destination) assuming
;; that source and destination do not overlap.
string_copy:
    test rdx, rdx
    jz .end

    mov al, [rsi]
    mov [rdi], al

    inc rdi
    inc rsi
    dec rdx
    jmp string_copy
.end:
    ret

;; Common Code Field routine for all colon words.
;;
;;     <--- Header ---><-- Code Field --><------- Paramater Field ------>
;;     +---------------+-----------------+-----------------------+------+
;;     | xxxxxxxxxxxxx |     DOCOL       | xxxxxxxxxxxxxxxxxxxxx | EXIT |
;;     +---------------+-----------------+-----------------------+------+
;;                     ^
;;                     w
;;   ---------+--------|--------+-----------------
;;   ........ | SOME-COLON-WORD | ................  (a thread)
;;   ---------+-----------------+-----------------
;;            ^                 ^
;;            |                 |
;;            pc(1)             pc(2)
;;
;; Let's say we encounter a colon word named SOME-COLON-WORD during the
;; process of executing some other word. Before `next`, our pc is at pc(1).
;; After `next`, our pc is at pc(2) and our w is the Code Field Address
;; of SOME-COLON-WORD. The last instruction of `next`, which is `jmp [w]`,
;; is exactly the same as `jmp DOCOL`. And here this what DOCOL does:
;;
;;   a. Pushes the current pc(2) onto the return stack, so that the
;;      interpeter knows where to go next when SOME-COLON-WORD is done
;;      (typically EXIT will pop this pc and pass the control back to
;;       the interpeter via `next`).
;;
;;   b. Sets w to point to SOME-COLON-WORD's Paramater Field
;;
;;   c. Sets pc to this new w and passes control back to the interpeter.
DOCOL:
    rpush pc
    add w, 8
    mov pc, w
    next

;; The default Code Field routine for all words created using `CREATE`.
;;
;;   +----------+---+---+---+---+---+-----+----------+------------
;;   |   LINK   | 0 | 3 | F | O | O | ... |  DOVAR   | ...........
;;   +----------+---+---+---+---+---+-----+----8-----+------------
;;                                        ^          ^
;;                                        |          |
;;                                       CFA        PFA (DFA)
;;
;; What DOVAR does is very simple: it pushes the address of the word's
;; Paramater Field (a.k.a Data Field) onto the data stack.
DOVAR:
    lea rax, riprel(w + 8)      ; Paramater Field Address, w = CFA
    push rax
    next

section .bss

;; Input Buffer
;; ------------
;; Stores a sequence of characters from the input source (stdin, file, etc..)
;; that is currently accessible to a program.
alignb INPUT_BUFFER_SIZE
input_buffer: resb INPUT_BUFFER_SIZE

;; Word Buffer
;; -----------
;; This buffer is used to store the counted string returned by read_word.
;; Subsequent calls overwrite this buffer.
;;
;; What the heck is a "counted-string"?
;;
;;     <-- 1 byte -->
;;     +------------+--------------......--------------+
;;     |     LEN    |            CHARACTERS            |
;;     +------------+--------------......--------------+
;;     ^
;;     |
;; word_buffer
alignb WORD_BUFFER_SIZE
word_buffer: resb WORD_BUFFER_SIZE

section .data
align 8

;; Stores the offset in characters from the start of the input buffer to
;; the start of the parse area.
;; The corresponding word is >IN.
input_buffer_offset: dq 0

;; Stores the current number of characters in the input buffer.
;; No corresponding word for this variable. It is here together with
;; `to_in` and `input_buffer` to help in the implementation of words,
;; such as SOURCE, KEY, etc...
input_buffer_length: dq 0
