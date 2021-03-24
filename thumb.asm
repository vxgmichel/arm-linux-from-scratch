
; A complete implementation of the THUMB instruction set

; Based on the following reference document:
; - https://edu.heibai.org/ARM%E8%B5%84%E6%96%99/ARM7-TDMI-manual-pt3.pdf

; Here's a list of differences with the reference document:
; - The `#` character, typically used for immediate values, is ommited
; - `ADD SP, -offset` is replaced with `SUB SP, offset`, for consistency
; - `LDR A1, label` is used as `LDR A1, [PC, offset]` with the offset being pre-computed from label
; - `ADR A1, label` is used as `ADD A1, PC, offset` with the offset being pre-computed from label
; - The `PUSH` syntax is `PUSH V1, ..., V2, LR`
; - The `POP` syntax is `POP V1, ..., V4, PC`


; Low registers and their aliases
#subruledef loregister
{
    R0 => 0`3
    R1 => 1`3
    R2 => 2`3
    R3 => 3`3
    R4 => 4`3
    R5 => 5`3
    R6 => 6`3
    R7 => 7`3

    A1 => 0`3
    A2 => 1`3
    A3 => 2`3
    A4 => 3`3
    V1 => 4`3
    V2 => 5`3
    V3 => 6`3
    V4 => 7`3

    FP => 7`3 ; Frame pointer in THUMB
}


; High registers and their aliases
#subruledef hiregister
{
    R8 => 0`3
    R9 => 1`3
    RA => 2`3 ; R10
    RB => 3`3 ; R11
    RC => 4`3 ; R12
    RD => 5`3 ; R13
    RE => 6`3 ; R14
    RF => 7`3 ; R15

    V5 => 0`3 ; R8
    V6 => 1`3 ; R9
    V7 => 2`3 ; R10
    V8 => 3`3 ; R11

    SB => 1`3 ; Static base
    SL => 2`3 ; Stack limit
    IP => 4`3 ; Intra-procedure call
    SP => 5`3 ; Stack pointer
    LR => 6`3 ; Link register
    PC => 7`3 ; Program counter
}

; Signed 8-bit half word label
#subruledef s8_half_word_label
{
    {label: u32} => {
        bits = 8
        limit = 1 << bits
        offset = label - ($ + 4)
        assert(offset[0:0] == 0)
        assert(offset >= -limit)
        assert(offset < limit)
        offset[8:1]
    }
}

; Signed 11-bit half word label
#subruledef s11_half_word_label
{
    {label: u32} => {
        bits = 11
        limit = 1 << bits
        offset = label - ($ + 4)
        assert(offset[0:0] == 0)
        assert(offset >= -limit)
        assert(offset < limit)
        offset[11:1]
    }
}

; Signed 22-bit half word label
#subruledef s22_half_word_label
{
    {label: u32} => {
        bits = 22
        limit = 1 << bits
        offset = label - ($ + 4)
        assert(offset[0:0] == 0)
        assert(offset >= -limit)
        assert(offset < limit)
        offset[22:1]
    }
}

; Unsigned 8-bit word label
#subruledef u8_word_label
{
    {label: u32} => {
        bits = 8
        limit = 1 << (bits + 2)
        offset = label - ($ + 4 & !0b10)
        assert(offset[1:0] == 0)
        assert(offset >= 0)
        assert(offset < limit)
        offset[9:2]
    }
}

; Register combination
#subruledef loregister_bits_1
{
    R0 => 0b000000001
    R1 => 0b000000010
    R2 => 0b000000100
    R3 => 0b000001000
    R4 => 0b000010000
    R5 => 0b000100000
    R6 => 0b001000000
    R7 => 0b010000000

    A1 => 0b000000001
    A2 => 0b000000010
    A3 => 0b000000100
    A4 => 0b000001000
    V1 => 0b000010000
    V2 => 0b000100000
    V3 => 0b001000000
    V4 => 0b010000000

    FP => 0b010000000 ; Frame pointer in THUMB

    LR => 0b100000000 ; Indicate LR should be pushed onto the stack
    PC => 0b100000000 ; Indicate PC should be popped from the stack
}

#subruledef loregister_bits_2
{
    {a: loregister_bits_1}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_3
{
    {a: loregister_bits_2}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_4
{
    {a: loregister_bits_3}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_5
{
    {a: loregister_bits_4}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_6
{
    {a: loregister_bits_5}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_7
{
    {a: loregister_bits_6}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_8
{
    {a: loregister_bits_7}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits_9
{
    {a: loregister_bits_8}, {b: loregister_bits_1} => (a | b)`9
}

#subruledef loregister_bits
{
    {a: loregister_bits_1} => a
    {a: loregister_bits_2} => a
    {a: loregister_bits_3} => a
    {a: loregister_bits_4} => a
    {a: loregister_bits_5} => a
    {a: loregister_bits_6} => a
    {a: loregister_bits_7} => a
    {a: loregister_bits_8} => a
    {a: loregister_bits_9} => a
}


; 16-bit THUMB instructions
#subruledef half_word_thumb
{
    ; Move shifted register
    MOV {rd: loregister}, {rs: loregister}            => 0b000 @ 0b00 @ 0`5 @ rs @ rd
    LSL {rd: loregister}, {rs: loregister}, {off: u5} => 0b000 @ 0b00 @ off`5 @ rs @ rd
    LSR {rd: loregister}, {rs: loregister}, {off: u5} => 0b000 @ 0b01 @ off`5 @ rs @ rd
    ASR {rd: loregister}, {rs: loregister}, {off: u5} => 0b000 @ 0b10 @ off`5 @ rs @ rd

    ; Add/substract
    ADD {rd: loregister}, {rn: loregister}                   => 0b00011 @ 0b0 @ 0b0 @ rn @ rd @ rd
    ADD {rd: loregister}, {rs: loregister}, {rn: loregister} => 0b00011 @ 0b0 @ 0b0 @ rn @ rs @ rd
    ADD {rd: loregister}, {rs: loregister}, {off: u3}        => 0b00011 @ 0b1 @ 0b0 @ off`3 @ rs @ rd
    SUB {rd: loregister}, {rn: loregister}                   => 0b00011 @ 0b0 @ 0b1 @ rn @ rd @ rd
    SUB {rd: loregister}, {rs: loregister}, {rn: loregister} => 0b00011 @ 0b0 @ 0b1 @ rn @ rs @ rd
    SUB {rd: loregister}, {rs: loregister}, {off: u3}        => 0b00011 @ 0b1 @ 0b1 @ off`3 @ rs @ rd

    ; Move/compare/add/subtract immediate
    MOV {rd: loregister}, {off: u8} => 0b001 @ 0b00 @ rd @ off`8
    CMP {rd: loregister}, {off: u8} => 0b001 @ 0b01 @ rd @ off`8
    ADD {rd: loregister}, {off: u8} => 0b001 @ 0b10 @ rd @ off`8
    SUB {rd: loregister}, {off: u8} => 0b001 @ 0b11 @ rd @ off`8

    ; ALU operations
    AND {rd: loregister}, {rs: loregister} => 0b010000 @ 0x0 @ rs @ rd
    EOR {rd: loregister}, {rs: loregister} => 0b010000 @ 0x1 @ rs @ rd
    LSL {rd: loregister}, {rs: loregister} => 0b010000 @ 0x2 @ rs @ rd
    LSR {rd: loregister}, {rs: loregister} => 0b010000 @ 0x3 @ rs @ rd
    ASR {rd: loregister}, {rs: loregister} => 0b010000 @ 0x4 @ rs @ rd
    ADC {rd: loregister}, {rs: loregister} => 0b010000 @ 0x5 @ rs @ rd
    SBC {rd: loregister}, {rs: loregister} => 0b010000 @ 0x6 @ rs @ rd
    ROR {rd: loregister}, {rs: loregister} => 0b010000 @ 0x7 @ rs @ rd
    TST {rd: loregister}, {rs: loregister} => 0b010000 @ 0x8 @ rs @ rd
    NEG {rd: loregister}, {rs: loregister} => 0b010000 @ 0x9 @ rs @ rd
    CMP {rd: loregister}, {rs: loregister} => 0b010000 @ 0xa @ rs @ rd
    CMN {rd: loregister}, {rs: loregister} => 0b010000 @ 0xb @ rs @ rd
    ORR {rd: loregister}, {rs: loregister} => 0b010000 @ 0xc @ rs @ rd
    MUL {rd: loregister}, {rs: loregister} => 0b010000 @ 0xd @ rs @ rd
    BIC {rd: loregister}, {rs: loregister} => 0b010000 @ 0xe @ rs @ rd
    MVN {rd: loregister}, {rs: loregister} => 0b010000 @ 0xf @ rs @ rd

    ; Hi register operations
    ADD {rd: loregister},  {hs: hiregister} => 0b010001 @ 0b00 @ 0b01 @ hs @ rd
    ADD {hd: hiregister},  {rs: loregister} => 0b010001 @ 0b00 @ 0b10 @ rs @ hd
    ADD {hd: hiregister},  {hs: hiregister} => 0b010001 @ 0b00 @ 0b11 @ hs @ hd
    CMP {rd: loregister},  {hs: hiregister} => 0b010001 @ 0b01 @ 0b01 @ hs @ rd
    CMP {hd: hiregister},  {rs: loregister} => 0b010001 @ 0b01 @ 0b10 @ rs @ hd
    CMP {hd: hiregister},  {hs: hiregister} => 0b010001 @ 0b01 @ 0b11 @ hs @ hd
    MOV {rd: loregister},  {hs: hiregister} => 0b010001 @ 0b10 @ 0b01 @ hs @ rd
    MOV {hd: hiregister},  {rs: loregister} => 0b010001 @ 0b10 @ 0b10 @ rs @ hd
    MOV {hd: hiregister},  {hs: hiregister} => 0b010001 @ 0b10 @ 0b11 @ hs @ hd

    ; Branch exchange
    BX {rs: loregister} => 0b010001110 @ 0b0 @ rs @ 0o0
    BX {hs: hiregister} => 0b010001110 @ 0b1 @ hs @ 0o0

    ; PC-relative load
    LDR {rd: loregister}, [PC, {off: u10}]       => 0b01001 @ rd @ off[9:2]
    LDR {rd: loregister}, {label: u8_word_label} => 0b01001 @ rd @ label

    ; Load/store with register offset
    STR {rd: loregister}, [{rb: loregister}, {ro: loregister}]  => 0b0101 @ 0b0 @ 0b0 @ 0b0 @ ro @ rb @ rd
    STRB {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b0 @ 0b1 @ 0b0 @ ro @ rb @ rd
    LDR {rd: loregister}, [{rb: loregister}, {ro: loregister}]  => 0b0101 @ 0b1 @ 0b0 @ 0b0 @ ro @ rb @ rd
    LDRB {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b1 @ 0b1 @ 0b0 @ ro @ rb @ rd

    ; Load/store sign-extended byte/halfword
    STRH {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b0 @ 0b0 @ 0b1 @ ro @ rb @ rd
    LDRH {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b1 @ 0b0 @ 0b1 @ ro @ rb @ rd
    LDSB {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b0 @ 0b1 @ 0b1 @ ro @ rb @ rd
    LDSH {rd: loregister}, [{rb: loregister}, {ro: loregister}] => 0b0101 @ 0b1 @ 0b1 @ 0b1 @ ro @ rb @ rd

    ; Load/store with immediate offset
    STR {rd: loregister}, [{rb: loregister}, {off: u7}]  => 0b011 @ 0b0 @ 0b0 @ off[6:2] @ rb @ rd
    LDR {rd: loregister}, [{rb: loregister}, {off: u7}]  => 0b011 @ 0b0 @ 0b1 @ off[6:2] @ rb @ rd
    STRB {rd: loregister}, [{rb: loregister}, {off: u5}] => 0b011 @ 0b1 @ 0b0 @ off`5 @ rb @ rd
    LDRB {rd: loregister}, [{rb: loregister}, {off: u5}] => 0b011 @ 0b1 @ 0b1 @ off`5 @ rb @ rd

    ; Load/store halfword
    STRH {rd: loregister}, [{rb: loregister}, {off: u6}] => 0b1000 @ 0b0 @ off[5:1] @ rb @ rd
    LDRH {rd: loregister}, [{rb: loregister}, {off: u6}] => 0b1000 @ 0b1 @ off[5:1] @ rb @ rd

    ; SP-relative load/store
    STR {rd: loregister}, [SP, {off: u8}] => 0b1001 @0b0 @ rd @ off`8
    LDR {rd: loregister}, [SP, {off: u8}] => 0b1001 @0b1 @ rd @ off`8

    ; Load address
    ADD {rd: loregister}, PC, {off: u10}         => 0b1010 @ 0b0 @ rd @ off[9:2]
    ADR {rd: loregister}, {label: u8_word_label} => 0b1010 @ 0b0 @ rd @ label
    ADD {rd: loregister}, SP, {off: u10}         => 0b1010 @ 0b1 @ rd @ off[9:2]

    ; Add offset to stack pointer
    ADD SP, {off: u9} => 0b10110000 @ 0b0 @ off[8:2]
    SUB SP, {off: u9} => 0b10110000 @ 0b1 @ off[8:2]

    ; Push/pop registers
    PUSH {rlist: loregister_bits} => 0b1011 @ 0b0 @ 0b10 @ rlist
    POP {rlist: loregister_bits}   => 0b1011 @ 0b1 @ 0b10 @ rlist

    ; Multiple load/store
    STMIA {rb: loregister}!, {rlist: loregister_bits} => 0b1100 @ 0b0 @ rb @ rlist[7:0]
    LDMIA {rb: loregister}!, {rlist: loregister_bits} => 0b1100 @ 0b1 @ rb @ rlist[7:0]

    ; Conditional branch
    BEQ {label: s8_half_word_label} => 0b1101 @ 0x0 @ label
    BNE {label: s8_half_word_label} => 0b1101 @ 0x1 @ label
    BCS {label: s8_half_word_label} => 0b1101 @ 0x2 @ label
    BCC {label: s8_half_word_label} => 0b1101 @ 0x3 @ label
    BMI {label: s8_half_word_label} => 0b1101 @ 0x4 @ label
    BPL {label: s8_half_word_label} => 0b1101 @ 0x5 @ label
    BVS {label: s8_half_word_label} => 0b1101 @ 0x6 @ label
    BVC {label: s8_half_word_label} => 0b1101 @ 0x7 @ label
    BHI {label: s8_half_word_label} => 0b1101 @ 0x8 @ label
    BLS {label: s8_half_word_label} => 0b1101 @ 0x9 @ label
    BGE {label: s8_half_word_label} => 0b1101 @ 0xa @ label
    BLT {label: s8_half_word_label} => 0b1101 @ 0xb @ label
    BGT {label: s8_half_word_label} => 0b1101 @ 0xc @ label
    BLE {label: s8_half_word_label} => 0b1101 @ 0xd @ label

    ; Software Interrupt
    SWI {cmt: u8} => 0b11011111 @ cmt

    ; Unconditional branch
    B {label: s11_half_word_label} => 0b11100 @ label
}


; 32-bits THUMB instructions
#subruledef word_thumb
{
    ; Long branch with link
    BL {label: s22_half_word_label} => 0b11110 @ label[21:11] @ 0b11111 @ label[10:0]
}


; 64-bits ARM instruction for switching from ARM to THUMB
#subruledef switch_to_thumb
{
    ; Switch from ARM to THUMB
    STT => 0xe28f0001 @ 0xe12fff10 ; ADD R0, PC, #1; BX R0
}


; Expose all the rules as little endian
#ruledef little_endian_thumb
{
    {val: half_word_thumb}      => val[7:0] @ val[15:8]
    {val: word_thumb}           => val[23:16] @ val[31:24] @ val[7:0] @ val[15:8]
    {val: switch_to_thumb}      => val[39:32] @ val[47:40] @ val[55:48] @ val[63:56] @ val[7:0] @ val[15:8] @ val[23:16] @ val[31:24]
}

