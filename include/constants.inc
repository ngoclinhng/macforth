%ifndef MACFORTH_CONSTANTS_INC_
%define MACFORTH_CONSTANTS_INC_

SYSCALL_EXIT  equ 0x02000001
SYSCALL_READ  equ 0x02000003
SYSCALL_WRITE equ 0x02000004

STDIN_FILENO  equ 0
STDOUT_FILENO equ 1
STDERR_FILENO equ 2

;; The offset from the beginning of the name field of a word:
;; 8 bytes for link + 1 byte for padded zero.
;; See `macros.inc` for more infos.
NAME_FIELD_OFFSET equ 9

;; Size (in bytes) of the input buffer.
INPUT_BUFFER_SIZE equ 1024
%endif
