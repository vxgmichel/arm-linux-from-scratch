; A 32-bit ARM Linux program written in assembly using customasm.

; Convert lowercase ascii characters to uppercase.
; Other ascii characters are left untouched.
; Data is read from stdin and written to stdout.


; Load the THUMB instruction ruleset
#include "thumb.asm"

; Produce a static ELF executable
#include "elf.asm"


; Program bank as defined in `elf.asm`
#bank program

; Calling convention for subroutines:
; - V1, V2, V3, V4 and LR are pushed on the stack in the subroutine prologue
; - SP is maintained in order to remain unchanged as the subroutine returns
; - V1, V2, V3, V4 and LR are poped from the stack in the subroutine epilogue
; - Anything else might be affected by the call
; - http://www.cs.cornell.edu/courses/cs414/2001FA/armcallconvention.pdf

; Linux system calls for ARM 32-bit
; Based on the following table:
; - https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI
EXIT = 1
FORK = 2
READ = 3
WRITE = 4

; Linux file descriptors
STDIN = 0
STDOUT = 1
STDERR = 2


; Exit subroutine
; Arguments:
; - A1: Return code
; Return value:
; - Does not return
exit:
    MOV R7, EXIT ; Prepare an `exit` system call
    SWI 0        ; Perform the `exit` system call


; Read file descriptor subroutine
; Arguments:
; - A1: File descriptor
; - A2: Buffer address
; - A3: Maximum buffer size
; Return value:
; - A1: Number of bytes read
read:
    PUSH [0b11110000, LR] ; Push the context on the stack
    MOV R7, READ          ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    POP [0b11110000, PC]  ; Return from subroutine and restore context


; Write file descriptor subroutine
; Arguments:
; - A1: File descriptor
; - A2: Buffer address
; - A3: Number of bytes to write
; Return value:
; - A1: The number of bytes written
write:
    PUSH [0b11110000, LR] ; Push the context on the stack
    MOV R7, WRITE         ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    POP [0b11110000, PC]  ; Return from subroutine and restore context


; Uppercase subroutine
; Arguments:
; - A1: Address of the buffer to update
; - A2: Buffer size in bytes
; Local variables:
; - V1: Offset in bytes
; - V2: Current byte
; Return value:
; - No return value
uppercase:
    PUSH [0b11110000, LR] ; Push the context on the stack
    MOV V1, 0             ; Initialize offset
    .loop:
    CMP A2, V1            ; Test offset against buffer size
    BEQ .exit             ; End of buffer is reached
    LDRB V2, [A1, V1]     ; Read the byte at offset
    .test:
    CMP V2, "a"           ; Compare byte against "a"
    BMI .continue         ; The byte is too low
    CMP V2, "z" + 1       ; Compare byte against "z" + 1
    BPL .continue         ; The byte is too high
    SUB V2, 32            ; Decrement character by 32
    .continue:
    STRB V2, [A1, V1]     ; Write the byte back
    ADD V1, 1             ; Increment offset
    B .loop               ; Loop over
    .exit:
    POP [0b11110000, PC]  ; Return from subroutine and restore context


; String compare subroutine
; Arguments:
; - A1: Address of the first null-terminated bytestring
; - A2: Address of the second null-terminated bytestring
; Local variables:
; - A3: Offset in bytes
; - V1: Current byte in the first string
; - V2: Current byte in the second string
; Return value:
; - A1: (V1 - V2) for the first different byte, or 0 if the strings are equal
strcmp:
    PUSH [0b11110000, LR] ; Push the context on the stack
    MOV A3, 0             ; Initialize offset
    .loop:
    LDRB V1, [A1, A3]     ; Load a byte from A1
    LDRB V2, [A2, A3]     ; Load a byte from A2
    CMP V1, V2            ; Compare the bytes
    BNE .break            ; Bytes are different
    TST V1, V1            ; Compare against zero
    BEQ .break            ; Bytes are null
    ADD A3, 1             ; Increment offset
    B .loop               ; Loop over
    .break:
    SUB A1, [V1, V2]      ; Set the return value to the byte difference
    POP [0b11110000, PC]  ; Return from subroutine and restore context


; Program entry point as defined in `elf.asm`
program:
    STT                         ; Switch to THUMB

    .thumb_program:             ; Initialize stack registers:
    LDR A1, stack_base_address  ; Load stack base into A1
    MOV SB, A1                  ; Set stack base
    LDR A1, stack_limit_address ; Load stack limit into A1
    MOV SL, A1                  ; Set stack limit
    LDR V1, [SP, 0]             ; Load argc in V1
    ADD V2, [SP, 4]             ; Load argv in V2
    MOV SP, SB                  ; Set stack pointer

    .argparse:                  ; Parse arguments:
    CMP V1, 2                   ; Test argc >= 2
    BMI .run                    ; No argument provided, goto run
    LDR A1, [V2, 4]             ; Load argv[1] in A1
    LDR A2, help_arg_address    ; Load help_arg in A2
    BL strcmp                   ; Compare both argument
    TST A1, A1                  ; Test the result
    BNE .run                    ; Argument is not `--help`, goto run

    .help:                      ; Show help message:
    MOV A1, STDOUT              ; Prepare a write to stdout
    LDR A2, message_address     ; Load the message address
    MOV A3, MESSAGE_LENGTH      ; With the right length
    BL write                    ; Call the write subroutine
    B .exit                     ; Goto exit

    .run:                       ; Prepare the main run:
    SUB SP, 128                 ; Allocate 128 bytes on the stack
    MOV V3, SP                  ; And store the address in V3

    .loop:                      ; Loop over read calls:
    MOV A1, STDIN               ; Prepare a read from stdin
    MOV A2, V3                  ; Provide the address of the buffer
    MOV A3, 128                 ; Read at most 128 bytes
    BL read                     ; Call the read subroutine
    MOV V4, A1                  ; Save the result in V4

    BEQ .exit                   ; Exit if EOF is reached

    MOV A1, V3                  ; Prepare a buffer update
    MOV A2, V4                  ; Over the correct size
    BL uppercase                ; Call the uppercase subroutine

    MOV A1, STDOUT              ; Prepare a write to stdout
    MOV A2, V3                  ; Load the message address
    MOV A3, V4                  ; With the right length
    BL write                    ; Call the write subroutine

    B .loop                     ; Loop over

    .exit:                      ; Exit with 0:
    MOV A1, 0                   ; Set return code to 0
    BL exit                     ; Call the exit subroutine

    ; Addresses
    #align 32
    help_arg_address: ld32 help_arg
    message_address: ld32 message
    stack_limit_address: ld32 stack_limit
    stack_base_address: ld32 stack_base


; Read-only memory
help_arg: #d "--help\0"
message: #d "Usage: upper [OPTION]
Convert lowercase ascii characters to uppercase.

Other ascii characters are left untouched.
Data is read from stdin and written to stdout.

  --help  display this help and exit
"
MESSAGE_LENGTH = $ - message


; Stack of 1 KB - Full descending
; The `end_program` and `end_memory` labels are used by the program header bank
; to compute the size of the program segment in the file and in-memory.
end_program: #align 32
stack_limit: #res 1024
stack_base:
end_memory:
