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
    PUSH LR               ; Push the context on the stack
    MOV R7, READ          ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    POP PC                ; Return from subroutine and restore context


; Write file descriptor subroutine
; Arguments:
; - A1: File descriptor
; - A2: Buffer address
; - A3: Number of bytes to write
; Return value:
; - A1: The number of bytes written
write:
    PUSH LR               ; Push the context on the stack
    MOV R7, WRITE         ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    POP PC                ; Return from subroutine and restore context


; Alphabet-to-integer subroutine
; Arguments:
; - A1: String buffer
; Locals:
; - A2: Current byte
; - A3: Current result
; - A4: Constant: 10
; - V1: Constant: 0xf
; Return value:
; - A1: Corresponding integer
atoi:
    PUSH V1, LR           ; Push the context on the stack
    .init:                ; Initialize local variables
    MOV A3, 0             ; Current result is 0
    MOV A4, 10            ; Load constant 10 in A4
    MOV V1, 0xf           ; Load constant 0xf in V1
    .trim:                ; Trim spaces at the start of the string
    LDRB A2, [A1, 0]      ; Load current byte
    ADD A1, 1             ; Increment string pointer
    CMP A2, " "           ; Compare current byte with space character
    BEQ .trim             ; Keep trimming
    .loop:                ; Loop over integer characters
    AND A2, V1            ; Convert char to integer
    ADD A3, A2            ; Add integer to the current result
    LDRB A2, [A1, 0]      ; Load next char
    ADD A1, 1             ; Increment string pointer
    CMP A2, "\0"          ; Compare with null char
    BEQ .return           ; Return if end of string
    CMP A2, " "           ; Compare with space char
    BEQ .return           ; Return if end of data
    MUL A3, A4            ; Multiply result by 10 otherwise
    B .loop               ; And loop over
    .return:              ; Return the current result
    MOV A1, A3            ; Set the current result
    POP V1, PC            ; Return from subroutine and restore context


; Integer-to-alphabet subroutine
; Arguments:
; - A1: Integer
; - A2: String buffer
; Locals:
; - V1: Reverse string buffer
; - V2: Reverse string buffer with offset
; - V3: String buffer
; - V4: String buffer with offset
; Return value:
; - A1: String buffer
itoa:
    PUSH V1, V2, V3, V4, LR ; Push the context on the stack
    .init:                  ; Initialize local variables
    SUB SP, 64              ; Allocate 50 bytes on the stack
    MOV V1, SP              ; Store the address in V1
    MOV V2, SP              ; And to V2
    MOV V3, A2              ; Store buffer address to V3
    MOV V4, A2              ; And to V4
    .loop:                  ; Loop over division
    CMP A1, 0               ; Compare current quotient with 0
    BEQ .reverse            ; Break the loop
    MOV A2, 10              ; Prepare divmod by 10
    BL divmod               ; Call divmod
    ADD A2, 0x30            ; Convert remainder to digit
    STRB A2, [V2, 0]        ; Write digit to buffer
    ADD V2, 1               ; Increment buffer address
    B .loop                 ; Loop over
    .reverse:               ; Return the current result
    CMP V1, V2              ; Compare V1 and V2
    BEQ .result             ; Break out of the loop
    SUB V2, 1               ; Decrement reverse buffer address
    LDRB A1, [V2, 0]        ; Load current char from reverse buffer
    STRB A1, [V4, 0]        ; Store current char to buffer
    ADD V4, 1               ; Increment buffer address
    B .reverse              ; Loop over
    .result:
    MOV A1, "\0"            ; Set A1 to null char
    STRB A1, [V4, 0]        ; Write null char to V1
    MOV A1, V3              ; Set the result to the string buffer
    ADD SP, 64              ; Deallocate reverse buffer
    POP V1, V2, V3, V4, PC  ; Return from subroutine and restore context

; Length of string subroutine
; Arguments:
; - A1: String buffer
; Locals:
; - A2: Current byte
; - A3: Current result
; Return value:
; - A1: Length of string
strlen:
    PUSH LR           ; Push the context on the stack
    .init:            ; Initialize local variables
    MOV A3, 0         ; Initialize current result
    .loop:            ; Loop over chars in buffer string
    LDRB A2, [A1, A3] ; Load current byte
    ADD A3, 1         ; Increment the result
    CMP A2, "\0"      ; Compare with null char
    BNE .loop         ; Loop over
    .return:          ; Return the current result
    SUB A3, 1         ; Ignore null character
    MOV A1, A3        ; Set the current result
    POP PC            ; Return from subroutine and restore context


; Length of string subroutine
; Arguments:
; - A1: Dividend
; - A2: Divisor
; Locals:
; - A3: Current shift
; - A4: Current result
; Return value:
; - A1: quotient
; - A2: remainder
divmod:
    PUSH LR        ; Push the context on the stack
    .init:         ; Initialize local variables
    MOV A3, 1      ; Initialize current shift
    MOV A4, 0      ; Initialize current quotient
    .loop1:
    CMP A1, A2
    BMI .loop2
    LSL A2, A2, 1
    LSL A3, A3, 1
    B .loop1
    .loop2:
    LSR A2, A2, 1
    LSR A3, A3, 1
    BEQ .return
    CMP A1, A2
    BMI .loop2
    ADD A4, A3
    SUB A1, A2
    B .loop2
    .return:
    MOV A2, A1     ; Set the remainder
    MOV A1, A4     ; Set the quotient
    POP PC         ; Return from subroutine and restore context


; Program entry point as defined in `elf.asm`
#align 32
entry_point:
    STT                         ; Switch to THUMB

    .thumb_program:             ; Initialize stack registers:
    LDR A1, stack_base_address  ; Load stack base into A1
    MOV SB, A1                  ; Set stack base
    LDR A1, stack_limit_address ; Load stack limit into A1
    MOV SL, A1                  ; Set stack limit
    LDR V1, [SP, 0]             ; Load argc in V1
    ADD V2, SP, 4               ; Load argv in V2
    MOV SP, SB                  ; Set stack pointer

    .argparse:                  ; Parse arguments:
    LDR A1, [V2, 4]             ; Load first arg in A1
    BL atoi                     ; Convert to integer
    MOV V3, A1                  ; Move integer to V3
    LDR A1, [V2, 8]             ; Load second arg in A1
    BL atoi                     ; Convert to integer
    MOV V4, A1                  ; Move integer to V4

    .adder:                     ; Add the arguments
    ADD V1, V3, V4

    .convert:                   ; Convert the result
    SUB SP, 50                  ; Allocate 50 bytes on the stack
    MOV V2, SP                  ; And store the address in V2
    MOV A1, V1                  ; Prepare conversion of V1
    MOV A2, V2                  ; to the buffer in V2
    BL itoa                     ; Perform conversion
    BL strlen                   ; And compute length
    MOV V3, A1                  ; And store in V3

    MOV A1, "\n"                ; Load a line feed
    STRB A1, [V2, V3]           ; Add a line feed to V3
    ADD V3, 1                   ; Increment buffer size
    MOV A1, STDOUT              ; Prepare write to stdout
    MOV A2, V2                  ; Using the buffer in V2
    MOV A3, V3                  ; And length in V3
    BL write                    ; Perform the write call

    .exit:                      ; Exit with 0:
    MOV A1, 0                   ; Set return code to 0
    BL exit                     ; Call the exit subroutine

    ; Addresses
    #align 32
    stack_limit_address: ld32 stack_limit
    stack_base_address: ld32 stack_base


; Stack of 1 KB - Full descending
; The `end_program` and `end_memory` labels are used by the program header bank
; to compute the size of the program segment in the file and in-memory.
end_program: #align 32
stack_limit: #res 1024
stack_base:
end_memory:
