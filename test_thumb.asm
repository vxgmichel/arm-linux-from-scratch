; Load the THUMB instruction ruleset
#include "thumb.asm"

; Testing
#bankdef test {#addr 0, #size 8 * 1024 * 1024, #outp 1024 * 1024 * 8}
#bank test

; Move shifted register
MOV A1, A2
LSL A1, [A2, 31]
LSR A1, [A2, 31]
ASR A1, [A2, 31]

; Add/substract
ADD A1, A2
ADD A1, [A2, A2]
ADD A1, [A2, 7]
SUB A1, A2
SUB A1, [A2, A2]
SUB A1, [A2, 7]

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
ADD A1, [PC, 1023]
ADD A1, [SP, 1023]

; Add offset to Stack Pointer
ADD SP, 508
SUB SP, 508

; Push/pop registers
PUSH [0b11111111]
PUSH [0b11111111, LR]
POP [0b11111111]
POP [0b11111111, PC]

; Multiple load/store
STMIA A1!, 0b11111110
LDMIA A1!, 0b11111110

; Conditional branch
before1:
#res 240
BEQ before1 - $ - 4
BNE before1 - $ - 4
BCS before1 - $ - 4
BCC before1 - $ - 4
BMI before1 - $ - 4
BPL before1 - $ - 4
BVS before1 - $ - 4
BVC after1 - $ - 4
BHI after1 - $ - 4
BLS after1 - $ - 4
BGE after1 - $ - 4
BLT after1 - $ - 4
BGT after1 - $ - 4
BLE after1 - $ - 4
#res 244
after1:

; Software interrupt
SWI 255

; Unconditional branch
before2:
#res 2044
B before2 - $ - 4
B after2 - $ - 4
#res 2048
after2:

; Long branch with link
before3:
#res 4194300
BL before3 - $ - 4
BL after3 - $ - 4
#res 4194302
after3: