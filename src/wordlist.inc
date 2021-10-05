;; ( -- char )
;; KEY reads the next byte from stdin and pushes it onto the data stack.
;; See `read_char` from `utils.asm` for more details.
native "KEY", 3, KEY
    call read_char
    push rax
    next

;; ( "<spaces>name<space>" -- c-addr u )
;; Skips leading spaces (any character that has hex value less than or equal
;; to 0x20 including spaces, tabs, newlines, and so on). Parses a string
;; delimited by a blank from the input buffer.
;; `c-addr` is the address within the input buffer of the parsed string, and
;; `u` is its length.
;; See `parse_name` from `utils.asm` for more details.
native "PARSE-NAME", 10, PARSE_NAME
    call parse_name
    push rax
    push rdx
    next

;; ( c-addr u - n f )
;; Convert the string specified by `c-addr` (address) and `u` (length)
;; into an 8-byte integer `n`. If the conversion fails, the flag `f` is
;; set to 0 (all bits are 0), otherwise it is set to -1 (all bits are 1).
;;
;; The conversion algorithm (assuming positive number for simplicity) is as
;; follow:
;;
;;   a. n is initialized to the decimal 0.
;;
;;   b. For the next character c in the input string:
;;
;;      - Convert c into the corresponding decimal value d with respect to
;;        BASE. For example, if BASE is 16 and c is the character 'A', its
;;        decimal value would be 10. If this conversion fails, the algorithm
;;        stops and sets the flag f to 0.
;;
;;      - Update n: n <- n * BASE + d.
;;
;;      - End of the input string yet? If not, go back to step b, otherwise
;;        set the flag to -1 (all bits are 1) and terminate.
;;
;; IMPORTANT NOTE:
;; --------------
;;   1. If BASE is 2 (binary), the input string is expected to be prefixed
;;      with either '0b' (for positive number) or '-0b' (for negative
;;      number). For example: 0b1010(10), -0b1010(-10).
;;
;;   2. If BASE is 8 (octal), the input string is expected to be prefixed
;;      with either '0o' (for positive number) or '-0o' (for negative
;;      number). For example: 0o012(10), -0o012(-10).
;;
;;   3. If BASE is 10 (decimal) and the input string is prefixed with the
;;      minus sign '-', the result of the conversion would be a negative
;;      (8-byte) integer.
;;
;;   4. If BASE is 16 (hexadecimal), the input string is expected to be
;;      prefixed with either '0x' (for positive number) or '-0x' (for
;;      negative number). For example: '0xa'(10), '0xA'(10), '-0xa'(-10),
;;      '-0xA'(-10).
;;
;;   5. Other BASEs are not yet supported!
;;
;;   6. This is NOT a standard Forth word!
native "S>NUMBER?", 9, STRING_TO_NUMBER
    pop rsi                     ; length
    pop rdi                     ; address
    mov rdx, riprel(base)       ; base
    call string_to_int

    push rax                    ; number
    push rdx                    ; flag
    next

;; ( "<spaces>name<space>" -- )
;; Skip leading spaces. Parse `name` delimited by a space. Create the
;; Header Part for `name`.
;; This is how (part of) the data space looks like after the command
;; HEADER FOO
;;
;;           <-------------- Header ------------>
;;   ----------+--------+---+---+---+---+---+-----+-----------------
;;   ..........|  LINK  | 0 | 3 | F | O | O | ... | ................
;;   ----------+---8----+-1-+-1-+---+---+---+-----+-----------------
;;             ^                                  ^
;;             |                                  |
;;          latest(here before)                 here(after, 8-byte aligned)
;;
;; After the command HEADER FOO
;;
;;   a. `latest` points to FOO, i.e., the contents of the memory cell
;;      designated by `latest` is the address of the word FOO.
;;
;;   b. The data-space pointer `here` points to a memory cell - which is
;;      going to be the address of FOO's Code Field. `here` is guaranteed
;;      to be 8-byte aligned.
;;
;; Note that this is not a standard ANSI word.
native "HEADER", 6, HEADER
    ; rax = name's address, rdx = name's length
    call parse_name
    mov rsi, rax

    ; LINK
    mov rdi, riprel(here)       ; load the address of next free cell
    mov rax, riprel(latest)     ; load the address of last word
    mov [rdi], rax              ; write last word into free cell
    mov riprel(latest), rdi     ; update latest

    ; FLAGS
    add rdi, 8                  ; address of Flags Field
    mov byte [rdi], 0           ; no flags by default

    ; LENGTH
    inc rdi                     ; address of Length Field
    mov byte [rdi], dl          ; write length

    ; NAME
    inc rdi                     ; address of Name Field
    push rdi
    push rdx
    call string_copy            ; copy name (rdi=dst, rsi=src, rdx=len)
    pop rdx
    pop rdi

    ; Update here
    add rdi, rdx
    add rdi, 0x7
    and rdi, ~0x7
    mov riprel(here), rdi

    next

;; ( "<spaces>name<space>" -- )
;; Skip leading spaces. Parse `name` delimited by a space. Create new word
;; for `name` and append it to the wordlist.
;;
;; Example: CREATE FOO
;;
;;
;;           <-------------- Header ------------><- CF -><-- PA----
;; ----------+--------+---+---+---+---+---+-----+-------+-----------
;; ..........|  LINK  | 0 | 3 | F | O | O | ... | DOVAR | ..........
;; ----------+---8----+-1-+-1-+---+---+---+-----+---8---+-----------
;;           ^                                          ^
;;           |                                          |
;;        latest                                       here
;;
;; After the command `CREATE FOO`:
;;
;;   a. `latest` points to FOO, i.e., the contents of the memory cell
;;      designated by `latest` is the address of the word FOO.
;;
;;   b. The data-space pointer `here` points to the address of FOO's
;;      Parameter Field (a.k.a Data Field).
;;
;;   c. The contents of FOO's Code Field is DOVAR (a memory address), and
;;      what DOVAR does (when FOO is executed) is to put the address of
;;      FOO's Parameter Field ([here]) onto the data stack.
colon "CREATE", 6, CREATE
    dq code_field_addr(HEADER)
    dq code_field_addr(LIT), DOVAR
    dq code_field_addr(COMMA)
    dq code_field_addr(EXIT)

;; Starts a colon definition
; colon ":", 1, COLON
;     ; Create Header part
;     dq code_field_addr(HEADER)

;     ; Append DOCOL
;     dq code_field_addr(LIT), DOCOL
;     dq code_field_addr(COMMA)

;     ; Mark the new definition as HIDDEN
;     dq code_field_addr(LATEST)
;     dq code_field_addr(FETCH)
;     dq code_field_addr(HIDDEN)

;     ; Enter compilation state
;     dq code_field_addr(RBRACKET)
;     dq code_field_addr(EXIT)

;; ( i * x xt -- j * x )
;; Remove xt (Code Field Address) from the stack and perform the semantics
;; identified by it. Other stack effects are due to the word EXECUTEd.
native "EXECUTE", 7, EXECUTE
    pop w
    jmp [w]

;; ( c-addr u -- header_field_addr | 0 )
;; Takes as inputs an address of a string `c-addr` (NOS) and its character
;; count `u` (TOS), and returns the Header Field Address of the first word
;; in the wordlist whose name matches the given string. If no such word
;; was found, 0 is returned instead.
;; Note that this is not a standard ANSI word.
native "FIND-NAME", 9, FIND_NAME
    mov rsi, riprel(latest)     ; current word to compare with
    pop rdx                     ; character count of input string
.loop:
    mov rdi, [rsp]              ; address of the input string
    push rsi                    ; save current word

    add rsi, 8                  ; Flags Field Address
    mov al, F_HIDDEN            ; HIDDEN flag
    test al, byte [rsi]         ; is it a hidden word?
    jnz .skip                   ; if so, skip this word

    inc rsi                     ; Length Field Address
    cmp dl, byte [rsi]          ; are they of the same length?
    jne .skip                   ; if not, skip this word

    inc rsi                     ; Name Field Address

    push rdx                    ; save character count
    call string_case_compare    ; compare two strings (rdi, rsi, rdx)
    pop rdx                     ; restore character count

    test rax, rax               ; are they equal?
    jnz .found                  ; yes, they are
.skip:
    pop rsi                     ; restore current word
    mov rsi, [rsi]              ; load previous word
    test rsi, rsi               ; is it 0 (null-pointer)?
    jnz .loop                   ; if not, loop back
.not_found:
    mov qword [rsp], 0
    next
.found:
    pop rsi
    mov [rsp], rsi
    next

;; ( addr -- xt )
;; Converts a word's Header Field Address to its Code Field Address
;;
;;   +---------------+-----+-----+----...-----+---------------+
;;   +     LINK      +  F  +  L  +    NAME    + CODE ADDRESS  +
;;   +------ 8 ------+- 1 -+- 1 -+----...-----+----- 8 -------+
;;   ^                                        ^
;;   |                                        |
;; HFA(addr)                                CFA(xt, 8-byte aligned)
;;
;; Note that this is not a standard ANSI word.
native ">CFA", 4, TO_CFA
    pop rsi
    add rsi, 8                  ; Skip LINK
    inc rsi                     ; Skip F(lags)
    movzx rax, byte [rsi]       ; Load length into al
    inc rsi                     ; Skip L(ength)
    add rsi, rax                ; Skip NAME

    ; Since CFA is 8-byte aligned (see macros.inc), we have to round
    ; rsi up to the nearest multiple of 8.
    add rsi, 0x7
    and rsi, ~0x7
    push rsi
    jmp next

;; Enter interpretation state (i.e., set the variable STATE to 0).
;; This is an IMMEDIATE word because we would otherwise never be able to
;; switch back to the interpretation mode from compilation mode!
native "[", 1, LBRACKET, F_IMMEDIATE
    mov qword riprel(state), 0
    next

;; Enter compilation state (i.e., set the variable STATE to 1).
native "]", 1, RBRACKET
    mov qword riprel(state), 1
    next

;; A number that appears in a colon definition is called a "literal". For
;; example, the "4" in the definition
;;
;;   : FOUR-MORE 4 + ;
;;
;; The use of a literal in a colon definition requires two cells. The first
;; contains the Code Field Address of the word LIT which, when executed,
;; will push the contents of the second cell (the number itself) onto the
;; stack.
;;
;;   -------+------------+-------+-------+-------+-------+-------+-------
;;   ...... |   HEADER   | DOCOL |  LIT  |   4   |   +   |  EXIT | ......
;;   -------+------------+-------+-------+-------+-------+-------+-------
;;
;; When the colon compiler encounters a number, it first appends LIT to
;; the current definition, and then the number itself.
native "LIT", 3, LIT
    push qword [pc]
    add pc, 8
    next

;; ( x -- )
;; Reserve one cell of the data space and store x in the cell.
;;
;;   ---------------+-----------------+---------------
;;   ...............|        x        | ..............
;;   ---------------+-----------------+---------------
;;                  ^---- 8 bytes ----^
;;                  |                 |
;;                 here(before)      here(after)
;;
;; Note that: here(before) must be 8-byte aligned!
native ",", 1, COMMA
    mov rax, riprel(here)       ; here
    pop qword [rax]             ; store TOS (x) at here
    add qword riprel(here), 8   ; advance here to point to next cell
    next

;; Make the most recent definition an IMMEDIATE word.
;; Typical use: : X ... ; IMMEDIATE
native "IMMEDIATE", 9, IMMEDIATE
    mov rax, riprel(latest)     ; address of the latest word
    add rax, 8                  ; address of its Flags Field
    or byte[rax], F_IMMEDIATE   ; turn on IMMEDIATE Flag
    next

;; ( char -- )
;; Writes 1 byte to stdout. If TOS is not a single character code,
;; its lowest byte will be printed out instead.
native "EMIT", 4, EMIT
    pop rdi
    call print_char
    next

;; ( c-addr u -- )
;; Prints the character string specified by `c-addr` (address) and `u`
;; (length) to stdout.
native "TYPE", 4, TYPE
    pop rsi                     ; length
    pop rdi                     ; address
    call print_string
    next

;; ( u -- )
;; Converts the unsigned integer at TOS using the value stored at base
;; as the radix for conversion, and prints the result out to stdout.
native "U.", 2, U_DOT
    pop rdi
    mov rsi, riprel(base)
    call print_uint
    next

;; ( n -- )
;; Converts the (signed) integer at TOS using the value stored at base as
;; the radix for conversion, and prints the result out to stdout.
native ".", 1, DOT
    pop rdi
    mov rsi, riprel(base)
    call print_int
    next

;; We mark this word with the HIDDEN flags since this is not a standard
;; Forth word, but we want it to be here to make our tests easier.
;; Note also that INIT depends on the external `interpreter_stub`.
native "INIT", 4, INIT, F_HIDDEN
    lea rstack, riprel(rstack_top)
    mov riprel(stack_base), rsp
    mov pc, interpreter_stub
    next

;; Exit a colon word.
native "EXIT", 4, EXIT
    rpop pc
    next

;; ( -- a-addr )
;; `a-addr` is the address of a cell containing the compilation-state flag.
;; STATE is true (1) when in compilation state, false (0) otherwise.
;; Note: A program shall not directly alter the contents of STATE.
native "STATE", 5, STATE
    push_addr state
    next

;; ( -- a-addr )
;; `a-addr` is the address of a cell containing the current number-
;; conversion radix {{2..36}}.
native "BASE", 4, BASE
    push_addr base
    next

;; ( -- addr )
;; `addr` is the data-space pointer.
native "HERE", 4, HERE
    push qword riprel(here)
    next

;; ( -- a-addr )
;; `a-addr` is the address of a cell containing the address of the very
;; last word in the dictionary (wordlist).
;; Note that a program shall not directly alter the contents of LATEST.
native "LATEST", 6, LATEST
    push_addr latest
    next
