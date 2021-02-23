; A simple ELF static executable for 32-bit ARM processor.
; It contains a single program segment.

; Based on the information provided by the video
; - "In-depth: ELF - The Extensible & Linkable Format"
; - By stacksmashing: https://youtu.be/nC1U1LJQL8o

; Sizes
ELF_HEADER_SIZE = 0x34          ; 32 bits ELF header size
PROGRAM_HEADER_SIZE = 0x20      ; 32 bits program header size
PROGRAM_SIZE = 0x1000           ; Loose upper bound for program size
ADDRESS_BASE = 0x1000           ; Use next memory page after 0

; Program offset
PROGRAM_OFFSET = 0x34 + 0x20                    ; In file
PROGRAM_ADDRESS = ADDRESS_BASE + PROGRAM_OFFSET ; In memory

; Segment access rights
PF_X = 0x1                      ; Execution access
PF_W = 0x2                      ; Write access
PF_R = 0x4                      ; Read access

; Little endian rules
#ruledef little_endian
{
    ld16 {val} => val[7:0] @ val[15:8]                           ; Equivalent to #d16
    ld32 {val} => val[7:0] @ val[15:8] @ val[23:16] @ val[31:24] ; Equivalent to #d32
}

; Bank definitions
#bankdef elf_header {#addr 0, #size ELF_HEADER_SIZE, #outp 0}
#bankdef program_header {#addr ELF_HEADER_SIZE, #size PROGRAM_HEADER_SIZE, #outp 8 * ELF_HEADER_SIZE}
#bankdef program {#addr PROGRAM_ADDRESS, #size PROGRAM_SIZE, #outp 8 * PROGRAM_OFFSET}

; ELF header
#bank elf_header
#d 0x7f, "ELF"                  ; Magic ELF number
#d 0x01                         ; 32 bits
#d 0x01                         ; LSB (little endian)
#d 0x01                         ; ELF version 1
#d 0x00                         ; No specific OS ABI
#d 0x00                         ; No specific ABI
#d8 0, 0, 0                     ; Padding
#d32 0                          ; Padding
ld16 2                          ; Static executable
ld16 0x28                       ; ARM
ld32 1                          ; ELF version 1
ld32 program                    ; Entry point
ld32 ELF_HEADER_SIZE            ; Program header offset
ld32 0                          ; Section header offset
ld32 0                          ; Flags
ld16 ELF_HEADER_SIZE            ; ELF header size
ld16 PROGRAM_HEADER_SIZE        ; Size per program header
ld16 1                          ; Number of program header
ld16 0                          ; Size per section header
ld16 0                          ; Number of section header
ld16 0                          ; Section header string table index

; Program header
#bank program_header
ld32 1                          ; Load type
ld32 PROGRAM_OFFSET             ; Program offset
ld32 PROGRAM_ADDRESS            ; Virtual address
ld32 PROGRAM_ADDRESS            ; Physicial address
ld32 PROGRAM_SIZE               ; Program size in the file
ld32 PROGRAM_SIZE               ; Program size in memory
ld32 PF_X | PF_W | PF_R         ; Execute, write and read flags
ld32 ADDRESS_BASE               ; Alignement