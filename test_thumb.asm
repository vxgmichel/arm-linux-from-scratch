; Write all the instructions in THUMB in order

; Useful for testing the THUMB ruleset against regression:
; $ customasm test_thumb.asm -p thumb_reference.bin
; $ <make some changes>
; $ customasm test_thumb.asm -p | diff thumb_reference.bin -

; Load the THUMB instruction ruleset
#include "thumb.asm"

; Testing
#bankdef test {#addr 0, #size 8 * 1024 * 1024, #outp 1024 * 1024 * 8}
#bank test

; Move shifted register
MOV A1, A2
LSL A1, A2, 31
LSR A1, A2, 31
ASR A1, A2, 31

; Add/substract
ADD A1, A2
ADD A1, A2, A2
ADD A1, A2, 7
SUB A1, A2
SUB A1, A2, A2
SUB A1, A2, 7

; Move/compare/add/subtract immediate
MOV A1, 255
CMP A1, 255
ADD A1, 255
SUB A1, 255

; ALU operations
AND A1, A2
EOR A1, A2
LSL A1, A2
LSR A1, A2
ASR A1, A2
ADC A1, A2
SBC A1, A2
ROR A1, A2
TST A1, A2
NEG A1, A2
CMP A1, A2
CMN A1, A2
ORR A1, A2
MUL A1, A2
BIC A1, A2
MVN A1, A2

; Hi register operations
ADD A1, SP
ADD SP, A1
ADD SP, V5
CMP A1, SP
CMP SP, A1
CMP SP, V5
MOV A1, SP
MOV SP, A1
MOV SP, V5

; Branch exchange
BX A1
BX V5

; PC-relative load
LDR A1, [PC, 1019]
LDR A1, label1
#res 1020
#align 32
label1: #d32 0

; Load/store with register offset
STR A1, [A2, A3]
STRB A1, [A2, A3]
LDR A1, [A2, A3]
LDRB A1, [A2, A3]

; Load/store sign-extended byte/halfword
STRH A1, [A2, A3]
LDRH A1, [A2, A3]
LDSB A1, [A2, A3]
LDSH A1, [A2, A3]

; Load/store with immediate offset
STR A1, [A2, 124]
LDR A1, [A2, 124]
STRB A1, [A2, 31]
LDRB A1, [A2, 31]

; Load/store halfword
STRH A1, [A2, 62]
LDRH A1, [A2, 62]

; SP-relative load/store
STR A1, [SP, 255]
LDR A1, [SP, 255]

; Load address
ADD A1, PC, 1023
ADD A1, SP, 1023
ADR A1, label2
#res 1020
#align 32
label2: #d32 0

; Add offset to Stack Pointer
ADD SP, 508
SUB SP, 508

; Push/pop registers
PUSH A1, A2, A3, A4
PUSH R0, R1, R2, R3
PUSH V1, V2, V3, V4
PUSH LR
PUSH A1, A2, A3, A4, LR
POP A1, A2, A3, A4
POP R0, R1, R2, R3
POP V1, V2, V3, V4
POP PC
POP V1, V2, V3, V4, PC

; Multiple load/store
STMIA A1!, V1, V2, V3, V4
LDMIA A1!, V1, V2, V3, V4

; Conditional branch
before1:
#res 240
BEQ before1
BNE before1
BCS before1
BCC before1
BMI before1
BPL before1
BVS before1
BVC after1
BHI after1
BLS after1
BGE after1
BLT after1
BGT after1
BLE after1
#res 244
after1:

; Software interrupt
SWI 255

; Unconditional branch
before2:
#res 2044
B before2
B after2
#res 2048
after2:

; Long branch with link
before3:
#res 4194300
BL before3
BL after3
#res 4194302
after3: