const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;

//pc should only have access to 16 bits
pub fn disassemble(buf: []u8, pc: u16) u8 {
    var op = buf[pc];
    var b1: u8 = 0;
    var b2: u8 = 0;
    if (pc < buf.len - 2) {
        b1 = buf[pc + 1];
        b2 = buf[pc + 2];
    }
    switch (op) {
        0x00 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     NOP\n", .{op});
            return 1;
        },
        0x01 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI B, 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x02 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STAX B\n", .{op});
            return 1;
        },
        0x03 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX B\n", .{op});
            return 1;
        },
        0x04 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR B\n", .{op});
            return 1;
        },
        0x05 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR B\n", .{op});
            return 1;
        },
        0x06 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI B,  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x07 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RLC\n", .{op});
            return 1;
        },
        0x09 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD B\n", .{op});
            return 1;
        },
        0x0a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     LDAX B\n", .{op});
            return 1;
        },
        0x0b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX B\n", .{op});
            return 1;
        },
        0x0c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR C\n", .{op});
            return 1;
        },
        0x0d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR C\n", .{op});
            return 1;
        },
        0x0e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI C, 0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x0f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RRC\n", .{op});
            return 1;
        },
        0x11 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI D, 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x12 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STAX D\n", .{op});
            return 1;
        },
        0x13 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX D\n", .{op});
            return 1;
        },
        0x14 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR D\n", .{op});
            return 1;
        },
        0x15 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR D\n", .{op});
            return 1;
        },
        0x16 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI D,  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x17 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RAL\n", .{op});
            return 1;
        },
        0x19 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD D\n", .{op});
            return 1;
        },
        0x1a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     LDAX D\n", .{op});
            return 1;
        },
        0x1b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX D\n", .{op});
            return 1;
        },
        0x1c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR E\n", .{op});
            return 1;
        },
        0x1d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR E\n", .{op});
            return 1;
        },
        0x1e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI E, 0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x1f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RAR\n", .{op});
            return 1;
        },
        0x21 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI H, 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x22 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m SHLD 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x23 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX H\n", .{op});
            return 1;
        },
        0x24 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR H\n", .{op});
            return 1;
        },
        0x25 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR H\n", .{op});
            return 1;
        },
        0x26 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI H, 0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x27 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAA\n", .{op});
            return 1;
        },
        0x29 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD H\n", .{op});
            return 1;
        },
        0x2a => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LHLD 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x2b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX H\n", .{op});
            return 1;
        },
        0x2c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR L\n", .{op});
            return 1;
        },
        0x2d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR L\n", .{op});
            return 1;
        },
        0x2e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI L,  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x2f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMA\n", .{op});
            return 1;
        },
        0x31 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI SP, 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x32 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m STA 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x33 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX SP\n", .{op});
            return 1;
        },
        0x34 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR M\n", .{op});
            return 1;
        },
        0x35 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR M\n", .{op});
            return 1;
        },
        0x36 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI M, 0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x37 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STC\n", .{op});
            return 1;
        },
        0x39 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD SP\n", .{op});
            return 1;
        },
        0x3a => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LDA 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x3b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX SP\n", .{op});
            return 1;
        },
        0x3c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR A\n", .{op});
            return 1;
        },
        0x3d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR A\n", .{op});
            return 1;
        },
        0x3e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI A, 0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0x3f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMC\n", .{op});
            return 1;
        },
        0x40 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,B\n", .{op});
            return 1;
        },
        0x41 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,C\n", .{op});
            return 1;
        },
        0x42 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,D\n", .{op});
            return 1;
        },
        0x43 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,E\n", .{op});
            return 1;
        },
        0x44 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,H\n", .{op});
            return 1;
        },
        0x45 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,L\n", .{op});
            return 1;
        },
        0x46 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,M\n", .{op});
            return 1;
        },
        0x47 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,A\n", .{op});
            return 1;
        },
        0x48 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,B\n", .{op});
            return 1;
        },
        0x49 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,C\n", .{op});
            return 1;
        },
        0x4a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,D\n", .{op});
            return 1;
        },
        0x4b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,E\n", .{op});
            return 1;
        },
        0x4c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,H\n", .{op});
            return 1;
        },
        0x4d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,L\n", .{op});
            return 1;
        },
        0x4e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,M\n", .{op});
            return 1;
        },
        0x4f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,A\n", .{op});
            return 1;
        },
        0x50 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,B\n", .{op});
            return 1;
        },
        0x51 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,C\n", .{op});
            return 1;
        },
        0x52 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,D\n", .{op});
            return 1;
        },
        0x53 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,E\n", .{op});
            return 1;
        },
        0x54 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,H\n", .{op});
            return 1;
        },
        0x55 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,L\n", .{op});
            return 1;
        },
        0x56 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,M\n", .{op});
            return 1;
        },
        0x57 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,A\n", .{op});
            return 1;
        },
        0x58 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,B\n", .{op});
            return 1;
        },
        0x59 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,C\n", .{op});
            return 1;
        },
        0x5a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,D\n", .{op});
            return 1;
        },
        0x5b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,E\n", .{op});
            return 1;
        },
        0x5c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,H\n", .{op});
            return 1;
        },
        0x5d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,L\n", .{op});
            return 1;
        },
        0x5e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,M\n", .{op});
            return 1;
        },
        0x5f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,A\n", .{op});
            return 1;
        },
        0x60 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,B\n", .{op});
            return 1;
        },
        0x61 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,C\n", .{op});
            return 1;
        },
        0x62 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,D\n", .{op});
            return 1;
        },
        0x63 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,E\n", .{op});
            return 1;
        },
        0x64 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,H\n", .{op});
            return 1;
        },
        0x65 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,L\n", .{op});
            return 1;
        },
        0x66 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,M\n", .{op});
            return 1;
        },
        0x67 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,A\n", .{op});
            return 1;
        },
        0x68 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,B\n", .{op});
            return 1;
        },
        0x69 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,C\n", .{op});
            return 1;
        },
        0x6a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,D\n", .{op});
            return 1;
        },
        0x6b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,E\n", .{op});
            return 1;
        },
        0x6c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,H\n", .{op});
            return 1;
        },
        0x6d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,L\n", .{op});
            return 1;
        },
        0x6e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,M\n", .{op});
            return 1;
        },
        0x6f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,A\n", .{op});
            return 1;
        },
        0x70 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,B\n", .{op});
            return 1;
        },
        0x71 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,C\n", .{op});
            return 1;
        },
        0x72 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,D\n", .{op});
            return 1;
        },
        0x73 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,E\n", .{op});
            return 1;
        },
        0x74 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,H\n", .{op});
            return 1;
        },
        0x75 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,L\n", .{op});
            return 1;
        },
        0x76 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     HLT\n", .{op});
            return 1;
        },
        0x77 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,A\n", .{op});
            return 1;
        },
        0x78 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,B\n", .{op});
            return 1;
        },
        0x79 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,C\n", .{op});
            return 1;
        },
        0x7a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,D\n", .{op});
            return 1;
        },
        0x7b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,E\n", .{op});
            return 1;
        },
        0x7c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,H\n", .{op});
            return 1;
        },
        0x7d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,L\n", .{op});
            return 1;
        },
        0x7e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,M\n", .{op});
            return 1;
        },
        0x7f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,A\n", .{op});
            return 1;
        },
        0x80 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD B\n", .{op});
            return 1;
        },
        0x81 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD C\n", .{op});
            return 1;
        },
        0x82 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD D\n", .{op});
            return 1;
        },
        0x83 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD E\n", .{op});
            return 1;
        },
        0x84 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD H\n", .{op});
            return 1;
        },
        0x85 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD L\n", .{op});
            return 1;
        },
        0x86 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD M\n", .{op});
            return 1;
        },
        0x87 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD A\n", .{op});
            return 1;
        },
        0x88 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC B\n", .{op});
            return 1;
        },
        0x89 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC C\n", .{op});
            return 1;
        },
        0x8a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC D\n", .{op});
            return 1;
        },
        0x8b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC E\n", .{op});
            return 1;
        },
        0x8c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC H\n", .{op});
            return 1;
        },
        0x8d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC L\n", .{op});
            return 1;
        },
        0x8e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC M\n", .{op});
            return 1;
        },
        0x8f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC A\n", .{op});
            return 1;
        },
        0x90 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB B\n", .{op});
            return 1;
        },
        0x91 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB C\n", .{op});
            return 1;
        },
        0x92 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB D\n", .{op});
            return 1;
        },
        0x93 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB E\n", .{op});
            return 1;
        },
        0x94 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB H\n", .{op});
            return 1;
        },
        0x95 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB L\n", .{op});
            return 1;
        },
        0x96 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB M\n", .{op});
            return 1;
        },
        0x97 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB A\n", .{op});
            return 1;
        },
        0x98 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB B\n", .{op});
            return 1;
        },
        0x99 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB C\n", .{op});
            return 1;
        },
        0x9a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB D\n", .{op});
            return 1;
        },
        0x9b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB E\n", .{op});
            return 1;
        },
        0x9c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB H\n", .{op});
            return 1;
        },
        0x9d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB L\n", .{op});
            return 1;
        },
        0x9e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB M\n", .{op});
            return 1;
        },
        0x9f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB A\n", .{op});
            return 1;
        },
        0xa0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA B\n", .{op});
            return 1;
        },
        0xa1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA C\n", .{op});
            return 1;
        },
        0xa2 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA D\n", .{op});
            return 1;
        },
        0xa3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA E\n", .{op});
            return 1;
        },
        0xa4 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA H\n", .{op});
            return 1;
        },
        0xa5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA L\n", .{op});
            return 1;
        },
        0xa6 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA M\n", .{op});
            return 1;
        },
        0xa7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA A\n", .{op});
            return 1;
        },
        0xa8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA B\n", .{op});
            return 1;
        },
        0xa9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA C\n", .{op});
            return 1;
        },
        0xaa => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA D\n", .{op});
            return 1;
        },
        0xab => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA E\n", .{op});
            return 1;
        },
        0xac => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA H\n", .{op});
            return 1;
        },
        0xad => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA L\n", .{op});
            return 1;
        },
        0xae => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA M\n", .{op});
            return 1;
        },
        0xaf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA A\n", .{op});
            return 1;
        },
        0xb0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA B\n", .{op});
            return 1;
        },
        0xb1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA C\n", .{op});
            return 1;
        },
        0xb2 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA D\n", .{op});
            return 1;
        },
        0xb3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA E\n", .{op});
            return 1;
        },
        0xb4 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA H\n", .{op});
            return 1;
        },
        0xb5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA L\n", .{op});
            return 1;
        },
        0xb6 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA M\n", .{op});
            return 1;
        },
        0xb7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA A\n", .{op});
            return 1;
        },
        0xb8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP B\n", .{op});
            return 1;
        },
        0xb9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP C\n", .{op});
            return 1;
        },
        0xba => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP D\n", .{op});
            return 1;
        },
        0xbb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP E\n", .{op});
            return 1;
        },
        0xbc => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP H\n", .{op});
            return 1;
        },
        0xbd => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP L\n", .{op});
            return 1;
        },
        0xbe => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP M\n", .{op});
            return 1;
        },
        0xbf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP A\n", .{op});
            return 1;
        },
        0xc0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RNZ\n", .{op});
            return 1;
        },
        0xc1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP B\n", .{op});
            return 1;
        },
        0xc2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JNZ 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc3 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JMP 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CNZ 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH B\n", .{op});
            return 1;
        },
        0xc6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ADI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xc7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 0\n", .{op});
            return 1;
        },
        0xc8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RZ\n", .{op});
            return 1;
        },
        0xc9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RET\n", .{op});
            return 1;
        },
        0xca => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JZ 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CZ 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcd => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CALL 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xce => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ACI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xcf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 1\n", .{op});
            return 1;
        },
        0xd0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RNC\n", .{op});
            return 1;
        },
        0xd1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP D\n", .{op});
            return 1;
        },
        0xd2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JNC 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd3 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   OUT  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xd4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CNC 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH D\n", .{op});
            return 1;
        },
        0xd6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   SUI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xd7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 2\n", .{op});
            return 1;
        },
        0xd8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RC\n", .{op});
            return 1;
        },
        0xda => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JC 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xdb => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   IN  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xdc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CC 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xde => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   SBI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xdf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 3\n", .{op});
            return 1;
        },
        0xe0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RPO\n", .{op});
            return 1;
        },
        0xe1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP H\n", .{op});
            return 1;
        },
        0xe2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JPO 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XTHL\n", .{op});
            return 1;
        },
        0xe4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CPO 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH H\n", .{op});
            return 1;
        },
        0xe6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ANI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xe7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 4\n", .{op});
            return 1;
        },
        0xe8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RPE\n", .{op});
            return 1;
        },
        0xe9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PCHL\n", .{op});
            return 1;
        },
        0xea => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JPE 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xeb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XCHG\n", .{op});
            return 1;
        },
        0xec => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CPE 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xee => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   XRI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xef => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 5\n", .{op});
            return 1;
        },
        0xf0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RP\n", .{op});
            return 1;
        },
        0xf1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP PSW\n", .{op});
            return 1;
        },
        0xf2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JP 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DI\n", .{op});
            return 1;
        },
        0xf4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CP 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH PSW\n", .{op});
            return 1;
        },
        0xf6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ORI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xf7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 6\n", .{op});
            return 1;
        },
        0xf8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RM\n", .{op});
            return 1;
        },
        0xf9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SPHL\n", .{op});
            return 1;
        },
        0xfa => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JM 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     EI\n", .{op});
            return 1;
        },
        0xfc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CM 0x{x:0>2}{x:0>2}\n", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfe => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   CPI  0x{x:0>2}\n", .{ op, b1, b1 });
            return 2;
        },
        0xff => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 7\n", .{op});
            return 1;
        },
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x20, 0x18 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     NOP\n", .{op});
            return 1;
        },
    }
    return 0;
}

fn readEmuFile(file_name: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile(file_name, .{});
    defer file.close();
    //const file_reader: std.io.Reader = file.reader();
    return try file.readToEndAlloc(alloc, std.math.maxInt(usize));
}

pub fn main() !void {
    var arg_it = std.process.args();
    _ = arg_it.skip();
    //ArgIterator.next() could possibly return a null value - which means
    //the type it will return must be an 'optional' ?[]const u8
    //To counteract this, we use an if
    //In the following if, we check if the 'file_name' that
    //came from the iterator is null
    //If it isn't, then it will execute the block and assign the
    //pointer value to |name|. Name is now NOT an optional, and also guaranteed
    //to have a non-null value ([]u8)
    const file_name = arg_it.next();
    if (file_name) |name| {
        print("Want to open {s}, but zig hates me.\n", .{name});
        //Create arena allocator 'arena'
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const alloc = arena.allocator();
        //defer means execute at end of scope (main in this case)
        //Arena allocators deinit ALL memory allocated using it
        //once deinit() is called
        defer arena.deinit();
        var emuBuf = try readEmuFile(name, alloc);
        var i: u16 = 0;
        while (i <= emuBuf.len - 1) {
            print("0x{x:0>2}: ", .{i});
            var opSize = disassemble(emuBuf, i);
            //opSize of zero means invalid op :/
            if (opSize == 0) {
                break;
            }
            i += opSize;
        }
    }
}
