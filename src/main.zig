const std = @import("std");
const print = std.debug.print;

pub fn disassemble(buf: *i8, pc: *i8) u8 {
    var op = buf[pc];
    switch (op) {
        0x00 => {
            print("NOP\n");
            return 1;
        },
        0x01 => {
            print("LXI B,D16\n");
            return 3;
        },
        0x02 => {
            print("STAX B\n");
            return 1;
        },
        0x03 => {
            print("INX B\n");
            return 1;
        },
        0x04 => {
            print("INR B\n");
            return 1;
        },
        0x05 => {
            print("DCR B\n");
            return 1;
        },
        0x06 => {
            print("MVI B, D8\n");
            return 2;
        },
        0x07 => {
            print("RLC\n");
            return 1;
        },
        0x09 => {
            print("DAD B\n");
            return 1;
        },
        0x0a => {
            print("LDAX B\n");
            return 1;
        },
        0x0b => {
            print("DCX B\n");
            return 1;
        },
        0x0c => {
            print("INR C\n");
            return 1;
        },
        0x0d => {
            print("DCR C\n");
            return 1;
        },
        0x0e => {
            print("MVI C,D8\n");
            return 2;
        },
        0x0f => {
            print("RRC\n");
            return 1;
        },
        0x11 => {
            print("LXI D,D16\n");
            return 3;
        },
        0x12 => {
            print("STAX D\n");
            return 1;
        },
        0x13 => {
            print("INX D\n");
            return 1;
        },
        0x14 => {
            print("INR D\n");
            return 1;
        },
        0x15 => {
            print("DCR D\n");
            return 1;
        },
        0x16 => {
            print("MVI D, D8\n");
            return 2;
        },
        0x17 => {
            print("RAL\n");
            return 1;
        },
        0x19 => {
            print("DAD D\n");
            return 1;
        },
        0x1a => {
            print("LDAX D\n");
            return 1;
        },
        0x1b => {
            print("DCX D\n");
            return 1;
        },
        0x1c => {
            print("INR E\n");
            return 1;
        },
        0x1d => {
            print("DCR E\n");
            return 1;
        },
        0x1e => {
            print("MVI E,D8\n");
            return 2;
        },
        0x1f => {
            print("RAR\n");
            return 1;
        },
        0x21 => {
            print("LXI H,D16\n");
            return 3;
        },
        0x22 => {
            print("SHLD adr\n");
            return 3;
        },
        0x23 => {
            print("INX H\n");
            return 1;
        },
        0x24 => {
            print("INR H\n");
            return 1;
        },
        0x25 => {
            print("DCR H\n");
            return 1;
        },
        0x26 => {
            print("MVI H,D8\n");
            return 2;
        },
        0x27 => {
            print("DAA\n");
            return 1;
        },
        0x29 => {
            print("DAD H\n");
            return 1;
        },
        0x2a => {
            print("LHLD adr\n");
            return 3;
        },
        0x2b => {
            print("DCX H\n");
            return 1;
        },
        0x2c => {
            print("INR L\n");
            return 1;
        },
        0x2d => {
            print("DCR L\n");
            return 1;
        },
        0x2e => {
            print("MVI L, D8\n");
            return 2;
        },
        0x2f => {
            print("CMA\n");
            return 1;
        },
        0x31 => {
            print("LXI SP, D16\n");
            return 3;
        },
        0x32 => {
            print("STA adr\n");
            return 3;
        },
        0x33 => {
            print("INX SP\n");
            return 1;
        },
        0x34 => {
            print("INR M\n");
            return 1;
        },
        0x35 => {
            print("DCR M\n");
            return 1;
        },
        0x36 => {
            print("MVI M,D8\n");
            return 2;
        },
        0x37 => {
            print("STC\n");
            return 1;
        },
        0x39 => {
            print("DAD SP\n");
            return 1;
        },
        0x3a => {
            print("LDA adr\n");
            return 3;
        },
        0x3b => {
            print("DCX SP\n");
            return 1;
        },
        0x3c => {
            print("INR A\n");
            return 1;
        },
        0x3d => {
            print("DCR A\n");
            return 1;
        },
        0x3e => {
            print("MVI A,D8\n");
            return 2;
        },
        0x3f => {
            print("CMC\n");
            return 1;
        },
        0x40 => {
            print("MOV B,B\n");
            return 1;
        },
        0x41 => {
            print("MOV B,C\n");
            return 1;
        },
        0x42 => {
            print("MOV B,D\n");
            return 1;
        },
        0x43 => {
            print("MOV B,E\n");
            return 1;
        },
        0x44 => {
            print("MOV B,H\n");
            return 1;
        },
        0x45 => {
            print("MOV B,L\n");
            return 1;
        },
        0x46 => {
            print("MOV B,M\n");
            return 1;
        },
        0x47 => {
            print("MOV B,A\n");
            return 1;
        },
        0x48 => {
            print("MOV C,B\n");
            return 1;
        },
        0x49 => {
            print("MOV C,C\n");
            return 1;
        },
        0x4a => {
            print("MOV C,D\n");
            return 1;
        },
        0x4b => {
            print("MOV C,E\n");
            return 1;
        },
        0x4c => {
            print("MOV C,H\n");
            return 1;
        },
        0x4d => {
            print("MOV C,L\n");
            return 1;
        },
        0x4e => {
            print("MOV C,M\n");
            return 1;
        },
        0x4f => {
            print("MOV C,A\n");
            return 1;
        },
        0x50 => {
            print("MOV D,B\n");
            return 1;
        },
        0x51 => {
            print("MOV D,C\n");
            return 1;
        },
        0x52 => {
            print("MOV D,D\n");
            return 1;
        },
        0x53 => {
            print("MOV D,E\n");
            return 1;
        },
        0x54 => {
            print("MOV D,H\n");
            return 1;
        },
        0x55 => {
            print("MOV D,L\n");
            return 1;
        },
        0x56 => {
            print("MOV D,M\n");
            return 1;
        },
        0x57 => {
            print("MOV D,A\n");
            return 1;
        },
        0x58 => {
            print("MOV E,B\n");
            return 1;
        },
        0x59 => {
            print("MOV E,C\n");
            return 1;
        },
        0x5a => {
            print("MOV E,D\n");
            return 1;
        },
        0x5b => {
            print("MOV E,E\n");
            return 1;
        },
        0x5c => {
            print("MOV E,H\n");
            return 1;
        },
        0x5d => {
            print("MOV E,L\n");
            return 1;
        },
        0x5e => {
            print("MOV E,M\n");
            return 1;
        },
        0x5f => {
            print("MOV E,A\n");
            return 1;
        },
        0x60 => {
            print("MOV H,B\n");
            return 1;
        },
        0x61 => {
            print("MOV H,C\n");
            return 1;
        },
        0x62 => {
            print("MOV H,D\n");
            return 1;
        },
        0x63 => {
            print("MOV H,E\n");
            return 1;
        },
        0x64 => {
            print("MOV H,H\n");
            return 1;
        },
        0x65 => {
            print("MOV H,L\n");
            return 1;
        },
        0x66 => {
            print("MOV H,M\n");
            return 1;
        },
        0x67 => {
            print("MOV H,A\n");
            return 1;
        },
        0x68 => {
            print("MOV L,B\n");
            return 1;
        },
        0x69 => {
            print("MOV L,C\n");
            return 1;
        },
        0x6a => {
            print("MOV L,D\n");
            return 1;
        },
        0x6b => {
            print("MOV L,E\n");
            return 1;
        },
        0x6c => {
            print("MOV L,H\n");
            return 1;
        },
        0x6d => {
            print("MOV L,L\n");
            return 1;
        },
        0x6e => {
            print("MOV L,M\n");
            return 1;
        },
        0x6f => {
            print("MOV L,A\n");
            return 1;
        },
        0x70 => {
            print("MOV M,B\n");
            return 1;
        },
        0x71 => {
            print("MOV M,C\n");
            return 1;
        },
        0x72 => {
            print("MOV M,D\n");
            return 1;
        },
        0x73 => {
            print("MOV M,E\n");
            return 1;
        },
        0x74 => {
            print("MOV M,H\n");
            return 1;
        },
        0x75 => {
            print("MOV M,L\n");
            return 1;
        },
        0x76 => {
            print("HLT\n");
            return 1;
        },
        0x77 => {
            print("MOV M,A\n");
            return 1;
        },
        0x78 => {
            print("MOV A,B\n");
            return 1;
        },
        0x79 => {
            print("MOV A,C\n");
            return 1;
        },
        0x7a => {
            print("MOV A,D\n");
            return 1;
        },
        0x7b => {
            print("MOV A,E\n");
            return 1;
        },
        0x7c => {
            print("MOV A,H\n");
            return 1;
        },
        0x7d => {
            print("MOV A,L\n");
            return 1;
        },
        0x7e => {
            print("MOV A,M\n");
            return 1;
        },
        0x7f => {
            print("MOV A,A\n");
            return 1;
        },
        0x80 => {
            print("ADD B\n");
            return 1;
        },
        0x81 => {
            print("ADD C\n");
            return 1;
        },
        0x82 => {
            print("ADD D\n");
            return 1;
        },
        0x83 => {
            print("ADD E\n");
            return 1;
        },
        0x84 => {
            print("ADD H\n");
            return 1;
        },
        0x85 => {
            print("ADD L\n");
            return 1;
        },
        0x86 => {
            print("ADD M\n");
            return 1;
        },
        0x87 => {
            print("ADD A\n");
            return 1;
        },
        0x88 => {
            print("ADC B\n");
            return 1;
        },
        0x89 => {
            print("ADC C\n");
            return 1;
        },
        0x8a => {
            print("ADC D\n");
            return 1;
        },
        0x8b => {
            print("ADC E\n");
            return 1;
        },
        0x8c => {
            print("ADC H\n");
            return 1;
        },
        0x8d => {
            print("ADC L\n");
            return 1;
        },
        0x8e => {
            print("ADC M\n");
            return 1;
        },
        0x8f => {
            print("ADC A\n");
            return 1;
        },
        0x90 => {
            print("SUB B\n");
            return 1;
        },
        0x91 => {
            print("SUB C\n");
            return 1;
        },
        0x92 => {
            print("SUB D\n");
            return 1;
        },
        0x93 => {
            print("SUB E\n");
            return 1;
        },
        0x94 => {
            print("SUB H\n");
            return 1;
        },
        0x95 => {
            print("SUB L\n");
            return 1;
        },
        0x96 => {
            print("SUB M\n");
            return 1;
        },
        0x97 => {
            print("SUB A\n");
            return 1;
        },
        0x98 => {
            print("SBB B\n");
            return 1;
        },
        0x99 => {
            print("SBB C\n");
            return 1;
        },
        0x9a => {
            print("SBB D\n");
            return 1;
        },
        0x9b => {
            print("SBB E\n");
            return 1;
        },
        0x9c => {
            print("SBB H\n");
            return 1;
        },
        0x9d => {
            print("SBB L\n");
            return 1;
        },
        0x9e => {
            print("SBB M\n");
            return 1;
        },
        0x9f => {
            print("SBB A\n");
            return 1;
        },
        0xa0 => {
            print("ANA B\n");
            return 1;
        },
        0xa1 => {
            print("ANA C\n");
            return 1;
        },
        0xa2 => {
            print("ANA D\n");
            return 1;
        },
        0xa3 => {
            print("ANA E\n");
            return 1;
        },
        0xa4 => {
            print("ANA H\n");
            return 1;
        },
        0xa5 => {
            print("ANA L\n");
            return 1;
        },
        0xa6 => {
            print("ANA M\n");
            return 1;
        },
        0xa7 => {
            print("ANA A\n");
            return 1;
        },
        0xa8 => {
            print("XRA B\n");
            return 1;
        },
        0xa9 => {
            print("XRA C\n");
            return 1;
        },
        0xaa => {
            print("XRA D\n");
            return 1;
        },
        0xab => {
            print("XRA E\n");
            return 1;
        },
        0xac => {
            print("XRA H\n");
            return 1;
        },
        0xad => {
            print("XRA L\n");
            return 1;
        },
        0xae => {
            print("XRA M\n");
            return 1;
        },
        0xaf => {
            print("XRA A\n");
            return 1;
        },
        0xb0 => {
            print("ORA B\n");
            return 1;
        },
        0xb1 => {
            print("ORA C\n");
            return 1;
        },
        0xb2 => {
            print("ORA D\n");
            return 1;
        },
        0xb3 => {
            print("ORA E\n");
            return 1;
        },
        0xb4 => {
            print("ORA H\n");
            return 1;
        },
        0xb5 => {
            print("ORA L\n");
            return 1;
        },
        0xb6 => {
            print("ORA M\n");
            return 1;
        },
        0xb7 => {
            print("ORA A\n");
            return 1;
        },
        0xb8 => {
            print("CMP B\n");
            return 1;
        },
        0xb9 => {
            print("CMP C\n");
            return 1;
        },
        0xba => {
            print("CMP D\n");
            return 1;
        },
        0xbb => {
            print("CMP E\n");
            return 1;
        },
        0xbc => {
            print("CMP H\n");
            return 1;
        },
        0xbd => {
            print("CMP L\n");
            return 1;
        },
        0xbe => {
            print("CMP M\n");
            return 1;
        },
        0xbf => {
            print("CMP A\n");
            return 1;
        },
        0xc0 => {
            print("RNZ\n");
            return 1;
        },
        0xc1 => {
            print("POP B\n");
            return 1;
        },
        0xc2 => {
            print("JNZ adr\n");
            return 3;
        },
        0xc3 => {
            print("JMP adr\n");
            return 3;
        },
        0xc4 => {
            print("CNZ adr\n");
            return 3;
        },
        0xc5 => {
            print("PUSH B\n");
            return 1;
        },
        0xc6 => {
            print("ADI D8\n");
            return 2;
        },
        0xc7 => {
            print("RST 0\n");
            return 1;
        },
        0xc8 => {
            print("RZ\n");
            return 1;
        },
        0xc9 => {
            print("RET\n");
            return 1;
        },
        0xca => {
            print("JZ adr\n");
            return 3;
        },
        0xcc => {
            print("CZ adr\n");
            return 3;
        },
        0xcd => {
            print("CALL adr\n");
            return 3;
        },
        0xce => {
            print("ACI D8\n");
            return 2;
        },
        0xcf => {
            print("RST 1\n");
            return 1;
        },
        0xd0 => {
            print("RNC\n");
            return 1;
        },
        0xd1 => {
            print("POP D\n");
            return 1;
        },
        0xd2 => {
            print("JNC adr\n");
            return 3;
        },
        0xd3 => {
            print("OUT D8\n");
            return 2;
        },
        0xd4 => {
            print("CNC adr\n");
            return 3;
        },
        0xd5 => {
            print("PUSH D\n");
            return 1;
        },
        0xd6 => {
            print("SUI D8\n");
            return 2;
        },
        0xd7 => {
            print("RST 2\n");
            return 1;
        },
        0xd8 => {
            print("RC\n");
            return 1;
        },
        0xda => {
            print("JC adr\n");
            return 3;
        },
        0xdb => {
            print("IN D8\n");
            return 2;
        },
        0xdc => {
            print("CC adr\n");
            return 3;
        },
        0xde => {
            print("SBI D8\n");
            return 2;
        },
        0xdf => {
            print("RST 3\n");
            return 1;
        },
        0xe0 => {
            print("RPO\n");
            return 1;
        },
        0xe1 => {
            print("POP H\n");
            return 1;
        },
        0xe2 => {
            print("JPO adr\n");
            return 3;
        },
        0xe3 => {
            print("XTHL\n");
            return 1;
        },
        0xe4 => {
            print("CPO adr\n");
            return 3;
        },
        0xe5 => {
            print("PUSH H\n");
            return 1;
        },
        0xe6 => {
            print("ANI D8\n");
            return 2;
        },
        0xe7 => {
            print("RST 4\n");
            return 1;
        },
        0xe8 => {
            print("RPE\n");
            return 1;
        },
        0xe9 => {
            print("PCHL\n");
            return 1;
        },
        0xea => {
            print("JPE adr\n");
            return 3;
        },
        0xeb => {
            print("XCHG\n");
            return 1;
        },
        0xec => {
            print("CPE adr\n");
            return 3;
        },
        0xee => {
            print("XRI D8\n");
            return 2;
        },
        0xef => {
            print("RST 5\n");
            return 1;
        },
        0xf0 => {
            print("RP\n");
            return 1;
        },
        0xf1 => {
            print("POP PSW\n");
            return 1;
        },
        0xf2 => {
            print("JP adr\n");
            return 3;
        },
        0xf3 => {
            print("DI\n");
            return 1;
        },
        0xf4 => {
            print("CP adr\n");
            return 3;
        },
        0xf5 => {
            print("PUSH PSW\n");
            return 1;
        },
        0xf6 => {
            print("ORI D8\n");
            return 2;
        },
        0xf7 => {
            print("RST 6\n");
            return 1;
        },
        0xf8 => {
            print("RM\n");
            return 1;
        },
        0xf9 => {
            print("SPHL\n");
            return 1;
        },
        0xfa => {
            print("JM adr\n");
            return 3;
        },
        0xfb => {
            print("EI\n");
            return 1;
        },
        0xfc => {
            print("CM adr\n");
            return 3;
        },
        0xfe => {
            print("CPI D8\n");
            return 2;
        },
        0xff => {
            print("RST 7\n");
            return 1;
        },
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x20, 0x18 => {
            print("INVALID OPCODE\n");
            return 0;
        },
    }
}

pub fn main() !void {}
