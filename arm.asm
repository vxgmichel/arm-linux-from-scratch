; A very partial implementation of ARM instruction set

; Based on the information provided in the ARM7TDMI-S Data Sheet
; - https://iitd-plos.github.io/col718/ref/arm-instructionset.pdf

; Register definitions and aliases
#subruledef register
{
        R0 => 0x0
        R1 => 0x1
        R2 => 0x2
        R3 => 0x3
        R4 => 0x4
        R5 => 0x5
        R6 => 0x6
        R7 => 0x7
        R8 => 0x8
        R9 => 0x9
        RA => 0xa
        RB => 0xb
        RC => 0xc
        RD => 0xd
        RE => 0xe
        RF => 0xf
        A1 => 0x0
        A2 => 0x1
        A3 => 0x2
        A4 => 0x3
        V1 => 0x4
        V2 => 0x5
        V3 => 0x6
        V4 => 0x7
        V5 => 0x8
        V6 => 0x9
        V7 => 0xa
        V8 => 0xb
        WR => 0x7
        SB => 0x9
        SL => 0xa
        FP => 0xb 
        IP => 0xc
        SP => 0xd ; Stack pointer
        LR => 0xe ; Link register
        PC => 0xf ; Program counter
}

#subruledef condition
{
        EQ => 0x0
        NE => 0x1
        CS => 0x2
        CC => 0x3
        MI => 0x4
        PL => 0x5
        VS => 0x6
        VC => 0x7
        HI => 0x8
        LS => 0x9
        GE => 0xa
        LT => 0xb
        GT => 0xc
        LE => 0xd
        AL => 0xe
}
ALW = 0xe ; Default value when condition is missing (always)

#subruledef sflag
{
        S => 0b1
}

#subruledef shift_name
{
        LSL => 0b00
        ASL => 0b00
        LSR => 0b01
        ASR => 0b10
        ROR => 0b11
}

#subruledef shift
{
        {name: shift_name} {reg: register} => reg @ 0b0 @ name @ 0b1
        {name: shift_name} {val: u5}      => val @ name @ 0b0
}

#subruledef rotate
{
        ROR => 0
}

#subruledef reg_op2
{
        {reg: register} => 0x00 @ reg
        ({reg: register} {shi: shift}) => shi @ reg
}

#subruledef imm_op2
{
        {val: u8} => 0x0 @ val
        ({val: u8} {_: rotate} {rot: u5}) => (rot >> 1)`4 @ val
}

#subruledef so_opcode ; Single operand op code
{
        MOV => 0xd ; Move
        MVN => 0xf ; Move negation
}

#subruledef nr_opcode ; No result op code
{
        TST => 0x8 ; Test AND
        TEQ => 0x9 ; Test XOR
        CMP => 0xa ; Test SUB
        CMN => 0xb ; Test ADD
}

#subruledef to_opcode ; Two operand op code
{
        AND => 0x0 ; AND operation
        EOR => 0x1 ; XOR operation
        SUB => 0x2 ; Substraction
        RSB => 0x3 ; Reverse substraction
        ADD => 0x4 ; Addition
        ADC => 0x5 ; Addition plus carry
        SBC => 0x6 ; Substraction plus carry minus 1
        RSC => 0x7 ; Reverse substraction plus carry minus 1
        ORR => 0xc ; OR operation
        BIC => 0xe ; Bit clear operation (AND NOT)
}

#subruledef so_instruction ; Single operand instruction (12 bits)
{
        {opc: so_opcode} -                    => ALW @ 0b00 @ 0b0 @ opc @ 0b0
        {opc: so_opcode}|S -                  => ALW @ 0b00 @ 0b0 @ opc @ 0b1
        {opc: so_opcode}|{cnd: condition} -   => cnd @ 0b00 @ 0b0 @ opc @ 0b0
        {opc: so_opcode}|{cnd: condition}|S - => cnd @ 0b00 @ 0b0 @ opc @ 0b1
}

#subruledef nr_instruction ; No result instruction (12 bits)
{
        {opc: nr_opcode} -                  => ALW @ 0b00 @ 0b0 @ opc @ 0b1
        {opc: nr_opcode}|{cnd: condition} - => cnd @ 0b00 @ 0b0 @ opc @ 0b1
}

#subruledef to_instruction ; No result instruction (12 bits)
{
        {opc: to_opcode} -                    => ALW @ 0b00 @ 0b0 @ opc @ 0b0
        {opc: to_opcode}|S -                  => ALW @ 0b00 @ 0b0 @ opc @ 0b1
        {opc: to_opcode}|{cnd: condition} -   => cnd @ 0b00 @ 0b0 @ opc @ 0b0
        {opc: to_opcode}|{cnd: condition}|S - => cnd @ 0b00 @ 0b0 @ opc @ 0b1
}

; Operands
REG_OPR = 0x000                   ; Register operand
IMM_OPR = 0x020                   ; Immediate operand

; Operands
IMM_OFF = 0x000                   ; Immediate offset
REG_OFF = 0x020                   ; Register offset
PST_IDX = 0x000                   ; Post indexing (apply offset after access)
PRE_IDX = 0x010                   ; Pre indexing (apply offset before access)

#subruledef sdt_opcode
{
        STR => 0b0
        LTR => 0b1
}

#subruledef ltr_instruction ; Single data transfer instruction (12 bits)
{
        LTR -                    => ALW @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b0 @ 0b0 @ 0b1
        LTR|B -                  => ALW @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b1 @ 0b0 @ 0b1
        LTR|{cnd: condition} -   => cnd @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b0 @ 0b0 @ 0b1
        LTR|{cnd: condition}|B - => cnd @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b1 @ 0b0 @ 0b1
}

#subruledef str_instruction ; Single data transfer instruction (12 bits)
{
        STR -                    => ALW @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b0 @ 0b0 @ 0b0
        STR|B -                  => ALW @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b1 @ 0b0 @ 0b0
        STR|{cnd: condition} -   => cnd @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b0 @ 0b0 @ 0b0
        STR|{cnd: condition}|B - => cnd @ 0b01 @ 0b0 @ 0b1 @ 0b1 @ 0b1 @ 0b0 @ 0b0
}

; ARM instruction set
#subruledef arm
{
        ; Branch and exchange
        BX|{cnd: condition} - {reg: register}                  => cnd @ 0b000100101111111111110001 @ reg
        BX - {reg: register}                                   => ALW @ 0b000100101111111111110001 @ reg

        ; Branch with/without link
        B|{cnd: condition} - {adr: s26}                        => cnd @ 0b101 @ 0b0 @ ((adr - $ - 8) >> 2)`24
        B - {adr: s26}                                         => ALW @ 0b101 @ 0b0 @ ((adr - $ - 8) >> 2)`24
        BL|{cnd: condition} - {adr: s26}                       => cnd @ 0b101 @ 0b1 @ ((adr - $ - 8) >> 2)`24
        BL - {adr: s26}                                        => ALW @ 0b101 @ 0b1 @ ((adr - $ - 8) >> 2)`24

        ; Data processing
        {ins: so_instruction} {dst: register} < {src: reg_op2} => (ins | REG_OPR)`12 @ 0x0 @ dst @ src
        {ins: so_instruction} {dst: register} < {src: imm_op2} => (ins | IMM_OPR)`12 @ 0x0 @ dst @ src
        {ins: nr_instruction} {op1: register}, {op2: reg_op2}  => (ins | REG_OPR)`12 @ op1 @ 0x0 @ op2
        {ins: nr_instruction} {op1: register}, {op2: imm_op2}  => (ins | IMM_OPR)`12 @ op1 @ 0x0 @ op2
        {ins: to_instruction} {dst: register} < {op1: register}, {op2: reg_op2} => (ins | REG_OPR)`12 @ op1 @ dst @ op2
        {ins: to_instruction} {dst: register} < {op1: register}, {op2: imm_op2} => (ins | IMM_OPR)`12 @ op1 @ dst @ op2

        ; Single data transfer
        {ins: ltr_instruction} {dst: register} < {adr: u32}      => (ins | IMM_OFF | PRE_IDX)`12 @ 0xf @ dst @ (adr - $ - 8)`12
        {ins: ltr_instruction} {dst: register} < {adr: register} => (ins | IMM_OFF | PRE_IDX)`12 @ adr @ dst @ 0x000
        {ins: str_instruction} {adr: u32} < {src: register}      => (ins | IMM_OFF | PRE_IDX)`12 @ 0xf @ src @ (adr - $ - 8)`12
        {ins: str_instruction} {adr: register} < {src: register} => (ins | IMM_OFF | PRE_IDX)`12 @ adr @ src @ 0x000

        ; Software interrupt
        SWI|{cnd: condition} - {cmt: i24}                      => cnd @ 0b1111 @ cmt`24
        SWI - {cmt: i24}                                       => ALW @ 0b1111 @ cmt`24
}

; Little endian ARM instruction set
#ruledef le_arm
{
        {val: arm} => val[7:0] @ val[15:8] @ val[23:16] @ val[31:24]
}