; A 32-bit ARM Linux program written in assembly using customasm.

; Convert lowercase ascii characters to uppercase.
; Other ascii characters are left untouched. 
; Data is read from stdin and written to stdout.

; Produce a static ELF executable
#include "elf.asm"

; Load the ARM instruction ruleset
#include "arm.asm"

; Linux system calls for ARM 32-bit
; Based on the following table:
; https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI
EXIT = 1
FORK = 2
READ = 3
WRITE = 4

; Linux file descriptors
STDIN = 0
STDOUT = 1
STDERR = 2

; Program bank as defined in `elf.asm`
#bank program
program:

argparse:
LTR  - R0 < SP                          ; Load argc in R0
CMP  - R0, 2                            ; Test argc
B|MI - read                             ; No argument provided, goto read

ADD  - SP < SP, 8                       ; Increment the stack pointer twice
LTR  - R0 < SP                          ; Load argv[1] in R0
LTR  - R1 < R0                          ; Load the first 4 characters of argv[1] in R1
LTR  - R2 < helpref                     ; Load the first 4 characters of `--help` in R2
TEQ  - R1, R2                           ; Compare R1 and R2
B|NE - read                             ; Ignore if not equal

ADD  - R0 < R0, 4                       ; Increment arv[1]
LTR  - R1 < R0                          ; Load the next 4 characters of argv[1] in R1
LTR  - R2 < helpref + 4                 ; Load the next 4 characters of `--help` in R2
BIC  - R1 < R1, (0xff ROR 8)            ; Clear the last byte of R1
TEQ  - R1, R2                           ; Compare R1 and R2
B|NE - read                             ; Ignore if not equal

help:
MOV - R7 < WRITE                        ; Prepare `write` system call
MOV - R0 < STDOUT                       ; To stdout
LTR - R1 < message_address              ; Load the message address
MOV - R2 < MESSAGE_LENGTH               ; With the length returned by `read`
SWI - 0                                 ; Perform `write` system call
B   - exit                              ; Goto exit

read:
MOV - R7 < READ                         ; Prepare `read` system call
MOV - R0 < STDIN                        ; From stdin
LTR - R1 < buffer_address               ; Fill up buffer
MOV - R2 < 0x80                         ; Read at most 128 bytes
SWI - 0                                 ; Perform `read` system call

test:
MOV - R3 < R0                           ; Save return value in R3
TEQ  - R3, 0                            ; Test the length return by `read`
B|EQ - exit                             ; If 0, jump to exit

update:
MOV   - R2 < R3                         ; Move R3 in R2
LTR   - SP < buffer_address             ; Load buffer address into stack pointer 
loop: 
LTR|B  - R0 < SP                        ; Load current character in R0
CMP    - R0, "a"                        ; If character is greater or equand than "a"
B|MI   - continue                       ; ...
CMP    - R0, "z" + 1                    ; And lower than "z" + 1
SUB|MI - R0 < R0, 32                    ; Then decrement character by 32
continue:
STR|B  - SP < R0                        ; Store current character
ADD    - SP < SP, 1                     ; Increment stack pointer
SUB    - R2 < R2, 1                     ; Decrement R2
TEQ    - R2, 0                          ; If R2 is not zero
B|NE   - loop                           ; Then jump to loop

write:
MOV - R7 < WRITE                        ; Prepare `write` system call
MOV - R0 < STDOUT                       ; To stdout
LTR - R1 < buffer_address               ; Load buffer address to R1
MOV - R2 < R3                           ; With the length returned by `read`
SWI - 0                                 ; Perform `write` system call
B   - read                              ; Then back to reading

exit:
MOV - R7 < EXIT                         ; Prepare `exit` system call
MOV - R0 < 0                            ; Set return code to 0
SWI - 0                                 ; Perform `exit` system call

buffer_address: ld32 buffer
message_address: ld32 message
message: #d "Usage: upper [OPTION]
Convert lowercase ascii characters to uppercase.

Other ascii characters are left untouched. 
Data is read from stdin and written to stdout.

  --help  display this help and exit
"
MESSAGE_LENGTH = $ - message
helpref: #d "--help\0\0"
buffer: