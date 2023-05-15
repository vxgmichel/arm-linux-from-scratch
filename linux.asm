; Linux system calls for ARM 32-bit

; Based on the following table:
; - https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI


; System calls
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
    PRO                   ; Push the context on the stack
    MOV R7, READ          ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    RET                   ; Return from subroutine and restore context


; Write file descriptor subroutine
; Arguments:
; - A1: File descriptor
; - A2: Buffer address
; - A3: Number of bytes to write
; Return value:
; - A1: The number of bytes written
write:
    PRO                   ; Push the context on the stack
    MOV R7, WRITE         ; Prepare a `write` system call
    SWI 0                 ; Perform the `write` system call
    RET                   ; Return from subroutine and restore context
