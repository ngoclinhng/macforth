;; ( a -- )
;; Drop the TOS.
;;
;;   cell#  | initial |  drop
;;   -------------------------
;;     0    |   -16   |   73              (TOS)
;;     1    |    73   |    5              (NOS)
;;     2    |     5   |    2
;;     3    |     2   |
;;     4    |         |
native "drop", drop
    add rsp, 8
    jmp next

;; ( a -- a a)
;; Duplicates the TOS (top-of-stack) into NOS (next-on-stack).
;; Sample image of the Data Stack before and after `dup`:
;;
;;   cell#  | initial |  dup
;;   -------------------------
;;     0    |   -16   |  -16              (TOS)
;;     1    |    73   |  -16              (NOS)
;;     2    |     5   |   73
;;     3    |         |    5
;;     4    |         |
native "dup", dup
    push qword [rsp]
    jmp next

;; ( a b c -- b c a)
;; Rotates the top 3 numbers.
;; Sample image of the Data Stack before and after `rot`:
;;
;;   cell#  | initial |  rot
;;   -------------------------
;;     0    |   -16   |    5              (TOS)
;;     1    |    73   |  -16              (NOS)
;;     2    |     5   |   73
;;     3    |     2   |    2
;;     4    |         |
native "rot", rot
    pop rcx
    pop rdx
    pop rax
    push rdx
    push rcx
    push rax
    jmp next

;; ( a b -- b a)
; Exchanges the top 2 numbers.
native "swap", swap
    pop rax
    pop rdx
    push rax
    push rdx
    jmp next

;; (a b -- [a - b])
;; Subtract TOS from NOS and stores the result as new TOS.
;;
;;   cell#  | initial |   -
;;   -------------------------
;;     0    |   -16   |   89              (TOS)
;;     1    |    73   |    5              (NOS)
;;     2    |     5   |    2
;;     3    |     2   |
;;     4    |         |
native "-", sub
    pop rax
    sub [rsp], rax
    jmp next

;; ( x -- ) ( R: -- x)
;; Moves x (TOS of the Data Stack) to the return stack.
native ">r", to_r
    pop rax
    rpush rax
    jmp next

;; ( -- x ) ( R: x -- )
;; Moves x from the Return Stack to the Data Stack.
native "r>", r_from
    rpop rax
    push rax
    jmp next

;; ( -- x ) (R: x -- x)
;; Copies x from the return stack to the data stack.
native "r@", r_fetch
    push qword [rstack]
    jmp next

;; ( input_buffer_addr -- length )
;; Reads a word from stdin (skip leading spaces) into the buffer starting at
;; the address `input_buffer_addr`. Word's length will be pushed onto the
;; Data Stack.
;; TODO: What if readw failed?
native "word", word
    pop rdi
    mov rsi, INPUT_BUFFER_SIZE
    call readw
    push rdx
    jmp next

;; ( addr -- last_char length )
;; Reads next word from stdin (skip leading spaces) into the buffer starting
;; at the address `addr` (TOS). Reading stops when one of these characters
;; sp, nl, cr, ht is encountered, at end-of-file or error. Last character
;; encoutered will be NOS, and TOS will be word's length .
native "repl-word", repl_word
    pop rdi

    push r14
    push r15

    xor r14, r14
    mov r15, INPUT_BUFFER_SIZE
    dec r15

.first_char:
    push rdi
    call readc
    pop rdi

    cmp al, SP_CHAR_CODE
    je .first_char
    cmp al, HT_CHAR_CODE
    je .first_char

    cmp al, NL_CHAR_CODE
    je .end
    cmp al, CR_CHAR_CODE
    je .end

    test al, al
    jz .end

.loop:
    mov byte [rdi + r14], al
    inc r14

    push rdi
    call readc
    pop rdi

    cmp al, SP_CHAR_CODE
    je .end
    cmp al, HT_CHAR_CODE
    je .end
    cmp al, NL_CHAR_CODE
    je .end
    cmp al, CR_CHAR_CODE
    je .end

    test al, al
    jz .end

    ; The word is too long for the given buffer.
    cmp r14, r15
    je .end

    jmp .loop

.end:
    mov byte [rdi + r14], 0
    mov rdx, r14

    pop r15
    pop r14

    push rax
    push rdx

    jmp next


;; ( addr -- nun len )
;; Parses an integer from a null-terminated string stored in the buffer
;; starting at the address `addr`. After this word finished its execution,
;; TOS will be the length of the number (0 if failed), and NOS will be
;; the number itself.
native "number", number
    pop rdi
    call parsei
    push rax
    push rdx
    jmp next

;; ( addr -- header_field_addr | 0 )
;; Takes as input an address of a null-terminated string (`addr`) and returns
;; the address of the Header Field of the word in the word in the dictionary
;; whose name matches the given string. If no such word was found, 0 is
;; returned instead.
native "find", find
    ; Reads last word in the dictionary into rsi. To be precise, the content
    ; of the memory cell designated by `last_word_ptr` is the address of the
    ; last word's Header Field
    mov rsi, RIP_REL(last_word_ptr)
.loop:
    ; addr of null-terminated string (1st argument to istrequ)
    mov rdi, [rsp]

    ; address of the word's Name Field (2nd argument to istrequ). We also
    ; have to save rsi here so that it will survive istrequ call.
    push rsi
    add rsi, NAME_FIELD_OFFSET

    ; Compares two strings and restores previously saved rsi.
    call istrequ
    pop rsi

    ; If equal rax = 1, otherwise 0
    test rax, rax
    jnz .found

    ; rsi stores the address of the current word's Header Field. The first
    ; cell (8 bytes) of this field is yet another address - the address of
    ; the previous word's Header Field. If rsi is zero we know that we
    ; have reached the end of the dictionary and no such word was found.
    mov rsi, [rsi]
    test rsi, rsi
    jnz .loop
.not_found:
    mov qword [rsp], 0
    jmp next
.found:
    mov [rsp], rsi
    jmp next

;; ( header_field_addr -- code_field_addr )
;; Converts a word's Header Field Address to its Code Field Address
;; Consult `macros.inc` for the structure of a word.
native "cfa", cfa
    pop rsi
    add rsi, NAME_FIELD_OFFSET
.loop:
    mov al, [rsi]
    test al, al
    jz .end
    inc rsi
    jmp .loop
.end:
    add rsi, 2                  ; 1 for null-terminator + 1 for flags
    push rsi
    jmp next

;; ( -- a).
;; Pushes the content of the cell (8 - bytes) immediately followed this
;; word onto the Data Stack. (lit stands for literal).
native "lit", lit
    push qword [pc]
    add pc, 8
    jmp next

;; ( addr -- )
;; Prints a null-terminated string whose address if TOS.
native "prints", prints
    pop rdi
    call prints
    jmp next

;; Prints newline character to stdout. This word does not affect the
;; Data Stack.
native "printn", printn
    call printn
    jmp next

;; ( a -- )
;; Removes TOS from the Data Stack and displays it on stdout.
native ".", dot
    cmp qword RIP_REL(stack_base), rsp
    jbe .error
    pop rdi
    call printi
    call printn
    jmp next
.error:
    lea rdi, RIP_REL(empty_stack_error)
    call prints
    jmp next

;; Displays the stack without destroying it.
;;
;; [stack_base] --> +--------+
;;                  |   1    |
;;                  +--------+
;;                  |   2    |    (NOS)
;;                  +--------+
;;                  |   3    |    (TOS)
;;  rsp ----------> +--------+
native ".s", display_stack
    mov rcx, RIP_REL(stack_base)

    mov r8, 8
    mov rax, rcx
    sub rax, rsp
    xor rdx, rdx
    div r8
    mov rdi, rax

    push rcx
    push rdi

    mov rdi, 91
    call printc
    pop rdi

    call printi

    mov rdi, 93
    call printc

    mov rdi, 32
    call printc

    pop rcx

.loop:
    cmp rcx, rsp
    jbe .end

    sub rcx, 8
    mov rdi, [rcx]

    push rcx
    call printi
    mov rdi, 32
    call printc
    pop rcx

    jmp .loop

.end:
    call printn
    jmp next

;; ( code_field_addr -- )
;; Executes the word whose Code Field Address is TOS.
native "execute", execute
    pop w
    jmp [w]

;; ( tos -- )
;; Goto some label if TOS is zero.
;;
;;                     .                 .
;;                     .                 .
;;                     .                 .
;;                     +-----------------+
;;                     |       CFA       | (gotz)
;;       pc ---------> +-----------------+
;;                     | zero_tos_branch |
;;                     +-----------------+
;;                     .                 .
;;                     .                 .
;;                     .                 .
;; zero_tos_branch --> +-----------------+
;;                     |       CFA       |
;;                     +-----------------+
;;                     |       CFA       |
;;                     +-----------------+
;;                     |                 |
;;
native "gotz", gotz
    pop rax
    test rax, rax
    jnz .skip
    mov pc, [pc]
    jmp next
.skip:
    add pc, 8
    jmp next

;; Unconditionally jump
native "goto", goto
    mov pc, [pc]
    jmp next

;; ( -- input_buffer_addr )
;; Pushes the address of the input buffer onto the Data Stack.
native "ibuf", ibuf
    push_addr input_buffer
    jmp next

;; Initialization.
native "init", init
    mov qword RIP_REL(state_ptr), 0
    lea rstack, RIP_REL(rstack_base + 8 * RSTACK_SIZE)
    mov pc, interpreter_stub

    cmp qword RIP_REL(stack_base), 0
    je .first

    mov rsp, RIP_REL(stack_base)
    jmp next
.first:
    mov RIP_REL(stack_base), rsp
    jmp next

;; Terminates Macforth
native "bye", bye
    xor rdi, rdi
    jmp exit

;; Enters a colon word.
native "docolon", docolon
    rpush pc
    add w, 8
    mov pc, w
    jmp next

;; Exits a colon word.
native "exit", exit
    rpop pc
    jmp next

;; ( addr -- )
;; Prints undefined error message to stdout, assuming that the address of
;; the null-terminated string representing the (undefined) word's name is
;; TOS.
colon "printe", printe
    ; Prints "Error: "
    dq code_field_addr(lit)
    dq undefined_word_error
    dq code_field_addr(prints)

    ; Prints word's name
    dq code_field_addr(prints)

    ; Prints " is undefined"
    dq code_field_addr(lit)
    dq undefined_word_undef
    dq code_field_addr(prints)

    ; Exits COLON word
    dq code_field_addr(exit)

;; Macforth REPL
colon "repl", repl
.prompt:
    ; Prints the prompt ">>> ".
    dq code_field_addr(lit)
    dq prompt_string
    dq code_field_addr(prints)
.loop:
    ; Reads next word from stdin into the input buffer.
    ; TOS = word's length, NOS = last character read
    dq code_field_addr(ibuf)
    dq code_field_addr(repl_word)

    ; If word's length is 0, we know that we have encountered end-of-file,
    ; a newline, or a carriage return character. Note that this `gotz`
    ; will consume the TOS (word's length).
    gotz .zero_length

    ; Tries to find the word whose name matches the null-terminated
    ; string in the input buffer.
    dq code_field_addr(ibuf)
    dq code_field_addr(find)

    ; If such a word does indeed exist, its Code Field Address is now the
    ; TOS. Otherwise, TOS is zero. And since `gotz` will consume the TOS,
    ; we need to duplicate it in order to proceed (if TOS turns out not
    ; to be equal to 0).
    dq code_field_addr(dup)
    gotz .maybe_number

    ; At this point, TOS is the word's Header Field Address and NOS is
    ; the last character read. Firstly, we need to swap TOS and NOS, and
    ; then move the last character read to rstack. Secondly, we find
    ; the word's Code Field Address, and then execute it. And finally, we
    ; move the last character read back to TOS.
    dq code_field_addr(swap)
    dq code_field_addr(to_r)
    dq code_field_addr(cfa)
    dq code_field_addr(execute)
    dq code_field_addr(r_from)

    ; The last character has been read now TOS.
    goto .check_last_character

.maybe_number:
    ; First of all, we need to remove the 0 (previously pushed onto
    ; by the `dup` word, right before gotz .maybe_number)
    dq code_field_addr(drop)

    ; Tries to parse integer from the null-terminated string stored the
    ; Input Buffer. TOS will be length, and NOS will be the number.
    dq code_field_addr(ibuf)
    dq code_field_addr(number)

    ; If TOS is zero, we know that the input is not a number.
    gotz .undefined_word_error

    ; At this point, TOS = number, NOS = last character read.
    dq code_field_addr(swap)
    goto .check_last_character

.undefined_word_error:
    ; Drops the failed number.
    dq code_field_addr(drop)

    ; Prints error message.
    dq code_field_addr(ibuf)
    dq code_field_addr(printe)

    ; TODO: flush stdin before prompt user.
    goto .check_last_character

.check_last_character:
    ; The last character has been read now TOS. If is is '\0' we know
    ; that we have reached end-of-file.
    dq code_field_addr(dup)
    gotz .last_character_is_nul

    ; Or maybe it is a newline character
    dq code_field_addr(dup)
    dq code_field_addr(lit)
    dq NL_CHAR_CODE
    dq code_field_addr(sub)
    gotz .last_character_is_nl

    ; Or maybe it is a carriage return character
    dq code_field_addr(dup)
    dq code_field_addr(lit)
    dq CR_CHAR_CODE
    dq code_field_addr(sub)
    gotz .last_character_is_cr

    ; Just a normal character.
    ; TODO: if is is not a whitespace, we know that previous word was
    ; too long to fit the input buffer.
    goto .last_character_is_other

.last_character_is_nul:
    dq code_field_addr(drop)
    goto .end_of_file

.last_character_is_nl:
    dq code_field_addr(drop)
    goto .prompt

.last_character_is_cr:
    dq code_field_addr(drop)
    goto .prompt

.last_character_is_other:
    dq code_field_addr(drop)
    goto .loop

.zero_length:
    ; If the last character read is '\0', we know that we have encountered
    ; end-of-file.
    gotz .end_of_file

    ; Otherwise, last character must be either a newline or a carriage
    ; return character.
    goto .prompt

.end_of_file:
    dq code_field_addr(bye)
    dq code_field_addr(exit)

;; Since each test case will define its own interpreter.
;; TODO: this is just placeholder for now.
%ifndef TEST
section .rodata
interpreter_stub: dq code_field_addr(repl)
%endif
