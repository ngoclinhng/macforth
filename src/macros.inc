%ifndef MACFORTH_MACROS_INC_
%define MACFORTH_MACROS_INC_

;; Common syscall numbers
;; ----------------------
;; To see a list of all syscalls for the current Mac you need to:
;;
;;   1. Check the kernel version of your machine by typing `uname -v` in
;;      the shell, and hit RETURN. Here is the output from my current
;;      machine:
;;      `Darwin Kernel Version 19.6.0: Tue Nov 10 00:10:30 PST 2020;
;;       root:xnu-6153.141.10~1/RELEASE_X86_64`
;;      The kernel version of the current machine is `xnu-6153.141.10`.
;;
;;  2. Go to [1], and click on the directory corresponding to your kernel
;;     version. And then go to `bsd/kern/` directory. In this kern directory
;;     you'll find a file named `syscalls.master`, click on that file.
;;     You'll be presented with an HTML page containing all syscalls. The
;;     left most column contains syscall numbers, the right most function
;;     prototypes.
;;
;; Note that, on macOSX, you have to add `0x02000000` to the actual syscall
;; number.
;; [1] - https://opensource.apple.com/source/xnu/
%define SYSCALL_EXIT 0x02000001
%define SYSCALL_READ 0x02000003
%define SYSCALL_WRITE 0x02000004

;; Mnemonic names for stdin, stdout and stderr
%define STDIN_FILENO 0
%define STDOUT_FILENO 1
%define STDERR_FILENO 2

;; Mnemonic names for ASCII codes of common characters. (man ascii)
%define NUL_CHAR 0x00
%define SP_CHAR 0x20
%define NL_CHAR 0x0a
%define CR_CHAR 0x0d
%define HT_CHAR 0x09
%define START_COMMENT_CHAR 0x5c

;; Constants used by data segment in Macforth.
%define RSTACK_SIZE 1024        ; in cells (8 bytes each)
%define INPUT_BUFFER_SIZE 4096  ; in bytes
%define DATA_SPACE_SIZE 65536   ; in cells (8 bytes each)

%define MAX_WORD_LENGTH 255     ; since length field is 1 byte.
%define WORD_BUFFER_SIZE 256    ; nearest power of 2

;; Macforth's registers
%define w r15                   ; Working register
%define pc r14                  ; Interpreter Pointer (a.k.a Program Counter)
%define rstack r13              ; Return Stack Pointer


;; Word's FLAGS.
;; ------------
;; +----+----+----+----+----+----+----+----+
;; | 0  | 0  |  0 |  0 | 0  | 0  | HI | IM |
;; +----+----+----+----+----+----+----+----+
%define F_IMMEDIATE 0x01        ; Mark word as IMMEDIATE
%define F_HIDDEN 0x02           ; Mark word as HIDDEN

;; Helper macros to get a word's Header Field Address, Code Field Address,
;; and Code Address given the label.
%define head_field_addr(l) _hfa_ %+ l
%define code_field_addr(l) _cfa_ %+ l
%define code_addr(l) _ca_ %+ l

;; Link to previous word in the dictionary.
%define _link 0

;; Helper macro to create a native word.
;; ------------------------------------
;; native %1, %2, %3, %4 -> a native word.
;;
;; Arguments
;; ---------
;; %1: a word name (e.g., '+', '-', '.', 'dup').
;; %2: name's length.
;; %3: label
;; %4: flags
;;
;; Struture of a native word
;; -------------------------
;; HFA: Header Field Address (or word's address) - the address of the word's
;;      Header field. The memory cell (8 bytes) designated by HFA contains
;;      the address of the previous word's Header Field! (_link).
;;
;; CFA: Code Field Address - the address of the word's Code Field. The
;;      contents of the memory cell (8 bytes) designated by CFA is yet
;;      another address - the address of an assembly subroutine which
;;      performs the word!
;;
;; CA: Code Address - The address of an assembly subroutine which performs
;;     the word. (CFA -> CA -> assembly subroutine).
;;
;; F: Flags.
;;
;; L: name's length.
;;
;; <---------------- Header ----------------><- Code Field -><- assembly ->
;; +---------------+-----+-----+----...-----+---------------+-----...-----+
;; +     LINK      +  F  +  L  +    NAME    + CODE ADDRESS  +     CODE    +
;; +------ 8 ------+- 1 -+- 1 -+----...-----+----- 8 -------+-----...-----+
;; ^                                        ^               ^
;; |                                        |               |
;; HFA                                      CFA             CA
;;
;; NOTE
;; ----
;; 1. The word's name is stored as a counted string: one byte containing the
;;    length followed by zero or more contiguous bytes for characters. This
;;    implies that the maximum length of a name is 255.
%macro native 4
    section .data
        align 8
    head_field_addr(%3) :           ; HFA
        dq _link                    ; LINK
        db %4                       ; FLAGS
        db %2                       ; LENGTH
        db %1                       ; NAME
        align 8                     ; padding to next 8 bytes boundary.
    code_field_addr(%3) :           ; CFA
        dq code_addr(%3)            ; CA

    ; Reset _link to point to this word.
    %define _link head_field_addr(%3)

    section .text
    code_addr(%3) :                 ; Assembly implementation
%endmacro

;; native overloading for convenient (as most words will not use flags).
%macro native 3
    native %1, %2, %3, 0
%endmacro

;; Helper macro to create a colon word.
;; ------------------------------------
;; colon %1, %2, %3, %4 -> a colon word.
;;
;; Arguments (the same as that of the native macro)
;; ---------------------------------------------
;; %1: a word name (e.g., '+', '-', '.', 'dup').
;; %2: name's length.
;; %3: label
;; %4: flags
;;
;; Struture of a colon word
;; ------------------------
;; The structure of a colon word is mostly the same as that of a native
;; word, except:
;;
;; - The Code Address (8 consecutive bytes starting at CFA) is always
;;   the address of the same assembly implementation for all colon words
;;   (the so called DOCOL or ENTER).
;;
;; - Right after the Code Field is a number of consecutive cells (8 bytes
;;   each) - these are called Paramater Field. The contents of each cell in
;;   this field is the Code Field Address of a word that made up the colon
;;   definition. The last cell in this Paramater Field is always the Code
;;   Field Address of a native word EXIT - which exits the colon word.
%macro colon 4
    section .data
        align 8
    head_field_addr(%3) :           ; HFA
        dq _link                    ; LINK
        db %4                       ; FLAGS
        db %2                       ; LENGTH
        db %1                       ; NAME
        align 8                     ; padding to next 8 bytes boundary.
    code_field_addr(%3) :           ; CFA
        dq DOCOL                    ; DOCOL

    ; Reset _link to point to this word.
    %define _link head_field_addr(%3)
%endmacro

;; As most colon words don't use flags, we define another version of
;; colon which takes only three arguments for convenient.
%macro colon 3
    colon %1, %2, %3, 0
%endmacro

;; Helper macro to push data (reg/imm) onto the return stack.
%macro rpush 1
    sub rstack, 8
    mov qword [rstack], %1
%endmacro

;; Helper macro to pop data off the return stack into a register.
%macro rpop 1
    mov %1, qword [rstack]
    add rstack, 8
%endmacro

;; Helper macro to push an absolute, 32-bit address onto the data stack.
;; The reason for this is that Mach-O 64-bit format does not support
;; 32-bit absolute addresses. See [1] for more discustion about this.
;;
;; [1] - https://stackoverflow.com/questions/13091987/
;; x64-nasm-pushing-memory-addresses-onto-the-stack-call-function
%macro push_addr 1
    lea rax, [rel %1]
    push rax
%endmacro

%define riprel(a) [rel a]

;; Forth inner interpreter.
;;
;; At every moment, pc points to a cell in memory - which stores the address
;; of a word's Code Field (Code Field Address). The interpreter fetches
;; that address into the Working register (w), advances the pc by 8 (to
;; point to another CFA of another word in the thread), and then jumps to
;; the address stored at the memory location designated by the content of w.
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
%macro next 0
    mov w, [pc]
    add pc, 8
    jmp [w]
%endmacro

%endif
