const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;

// Struct representing flags register state
const CPUFlags = struct {
    z: u1 = 1,
    s: u1 = 1,
    p: u1 = 1,
    cy: u1 = 1,
    ac: u1 = 1,
    pad: u1 = 1,
};

// Struct representing the CPU
const CPU = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    h: u8,
    l: u8,
    sp: u16,
    pc: u16,
    cc: CPUFlags,
    memory: []u8,
};

pub fn printCpuStatus(pCpu: *CPU) void {
    var cpu = pCpu.*;
    print(" a: 0x{x:0>2}\n b: 0x{x:0>2}\n c: 0x{x:0>2}\n", .{ cpu.a, cpu.b, cpu.c });
    print(" d: 0x{x:0>2}\n e: 0x{x:0>2}\n h: 0x{x:0>2}\n l: 0x{x:0>2}\n", .{ cpu.d, cpu.e, cpu.h, cpu.l });
    print(" pc: 0x{x:0>2} [", .{cpu.pc});
    _ = disassemble(cpu.memory, cpu.pc);
    print("]\n sp: 0x{x:0>2}\n", .{cpu.sp});
    print(" z:{b} s:{b} p:{b} cy:{b} ac:{b} pab:{b}", .{ cpu.cc.z, cpu.cc.s, cpu.cc.p, cpu.cc.cy, cpu.cc.ac, cpu.cc.pad });
    print("\n\n", .{});
}

pub fn emulate(cpu: *CPU) void {
    var op: []u8 = cpu.memory[cpu.pc..(cpu.pc + 3)];
    switch (op[0]) {
        0x00 => {
            //NOP
            cpu.pc += 1;
        },
        0x01 => {
            //LXI B, D16
            cpu.c = op[1];
            cpu.b = op[2];
            cpu.pc += 3;
        },
        0x02 => {
            unimplementedOpcode();
        },
        0x03 => {
            unimplementedOpcode();
        },
        0x04 => {
            unimplementedOpcode();
        },
        0x05 => {
            unimplementedOpcode();
        },
        0x06 => {
            unimplementedOpcode();
        },
        0x07 => {
            unimplementedOpcode();
        },
        0x09 => {
            unimplementedOpcode();
        },
        0x0a => {
            unimplementedOpcode();
        },
        0x0b => {
            unimplementedOpcode();
        },
        0x0c => {
            unimplementedOpcode();
        },
        0x0d => {
            unimplementedOpcode();
        },
        0x0e => {
            unimplementedOpcode();
        },
        0x0f => {
            unimplementedOpcode();
        },
        0x11 => {
            unimplementedOpcode();
        },
        0x12 => {
            unimplementedOpcode();
        },
        0x13 => {
            unimplementedOpcode();
        },
        0x14 => {
            unimplementedOpcode();
        },
        0x15 => {
            unimplementedOpcode();
        },
        0x16 => {
            unimplementedOpcode();
        },
        0x17 => {
            unimplementedOpcode();
        },
        0x19 => {
            unimplementedOpcode();
        },
        0x1a => {
            unimplementedOpcode();
        },
        0x1b => {
            unimplementedOpcode();
        },
        0x1c => {
            unimplementedOpcode();
        },
        0x1d => {
            unimplementedOpcode();
        },
        0x1e => {
            unimplementedOpcode();
        },
        0x1f => {
            unimplementedOpcode();
        },
        0x21 => {
            unimplementedOpcode();
        },
        0x22 => {
            unimplementedOpcode();
        },
        0x23 => {
            unimplementedOpcode();
        },
        0x24 => {
            unimplementedOpcode();
        },
        0x25 => {
            unimplementedOpcode();
        },
        0x26 => {
            unimplementedOpcode();
        },
        0x27 => {
            unimplementedOpcode();
        },
        0x29 => {
            unimplementedOpcode();
        },
        0x2a => {
            unimplementedOpcode();
        },
        0x2b => {
            unimplementedOpcode();
        },
        0x2c => {
            unimplementedOpcode();
        },
        0x2d => {
            unimplementedOpcode();
        },
        0x2e => {
            unimplementedOpcode();
        },
        0x2f => {
            unimplementedOpcode();
        },
        0x31 => {
            unimplementedOpcode();
        },
        0x32 => {
            unimplementedOpcode();
        },
        0x33 => {
            unimplementedOpcode();
        },
        0x34 => {
            unimplementedOpcode();
        },
        0x35 => {
            unimplementedOpcode();
        },
        0x36 => {
            unimplementedOpcode();
        },
        0x37 => {
            unimplementedOpcode();
        },
        0x39 => {
            unimplementedOpcode();
        },
        0x3a => {
            unimplementedOpcode();
        },
        0x3b => {
            unimplementedOpcode();
        },
        0x3c => {
            unimplementedOpcode();
        },
        0x3d => {
            unimplementedOpcode();
        },
        0x3e => {
            unimplementedOpcode();
        },
        0x3f => {
            unimplementedOpcode();
        },
        0x40 => {
            unimplementedOpcode();
        },
        0x41 => {
            unimplementedOpcode();
        },
        0x42 => {
            unimplementedOpcode();
        },
        0x43 => {
            unimplementedOpcode();
        },
        0x44 => {
            unimplementedOpcode();
        },
        0x45 => {
            unimplementedOpcode();
        },
        0x46 => {
            unimplementedOpcode();
        },
        0x47 => {
            unimplementedOpcode();
        },
        0x48 => {
            unimplementedOpcode();
        },
        0x49 => {
            unimplementedOpcode();
        },
        0x4a => {
            unimplementedOpcode();
        },
        0x4b => {
            unimplementedOpcode();
        },
        0x4c => {
            unimplementedOpcode();
        },
        0x4d => {
            unimplementedOpcode();
        },
        0x4e => {
            unimplementedOpcode();
        },
        0x4f => {
            unimplementedOpcode();
        },
        0x50 => {
            unimplementedOpcode();
        },
        0x51 => {
            unimplementedOpcode();
        },
        0x52 => {
            unimplementedOpcode();
        },
        0x53 => {
            unimplementedOpcode();
        },
        0x54 => {
            unimplementedOpcode();
        },
        0x55 => {
            unimplementedOpcode();
        },
        0x56 => {
            unimplementedOpcode();
        },
        0x57 => {
            unimplementedOpcode();
        },
        0x58 => {
            unimplementedOpcode();
        },
        0x59 => {
            unimplementedOpcode();
        },
        0x5a => {
            unimplementedOpcode();
        },
        0x5b => {
            unimplementedOpcode();
        },
        0x5c => {
            unimplementedOpcode();
        },
        0x5d => {
            unimplementedOpcode();
        },
        0x5e => {
            unimplementedOpcode();
        },
        0x5f => {
            unimplementedOpcode();
        },
        0x60 => {
            unimplementedOpcode();
        },
        0x61 => {
            unimplementedOpcode();
        },
        0x62 => {
            unimplementedOpcode();
        },
        0x63 => {
            unimplementedOpcode();
        },
        0x64 => {
            unimplementedOpcode();
        },
        0x65 => {
            unimplementedOpcode();
        },
        0x66 => {
            unimplementedOpcode();
        },
        0x67 => {
            unimplementedOpcode();
        },
        0x68 => {
            unimplementedOpcode();
        },
        0x69 => {
            unimplementedOpcode();
        },
        0x6a => {
            unimplementedOpcode();
        },
        0x6b => {
            unimplementedOpcode();
        },
        0x6c => {
            unimplementedOpcode();
        },
        0x6d => {
            unimplementedOpcode();
        },
        0x6e => {
            unimplementedOpcode();
        },
        0x6f => {
            unimplementedOpcode();
        },
        0x70 => {
            unimplementedOpcode();
        },
        0x71 => {
            unimplementedOpcode();
        },
        0x72 => {
            unimplementedOpcode();
        },
        0x73 => {
            unimplementedOpcode();
        },
        0x74 => {
            unimplementedOpcode();
        },
        0x75 => {
            unimplementedOpcode();
        },
        0x76 => {
            unimplementedOpcode();
        },
        0x77 => {
            unimplementedOpcode();
        },
        0x78 => {
            unimplementedOpcode();
        },
        0x79 => {
            unimplementedOpcode();
        },
        0x7a => {
            unimplementedOpcode();
        },
        0x7b => {
            unimplementedOpcode();
        },
        0x7c => {
            unimplementedOpcode();
        },
        0x7d => {
            unimplementedOpcode();
        },
        0x7e => {
            unimplementedOpcode();
        },
        0x7f => {
            unimplementedOpcode();
        },
        0x80 => {
            unimplementedOpcode();
        },
        0x81 => {
            unimplementedOpcode();
        },
        0x82 => {
            unimplementedOpcode();
        },
        0x83 => {
            unimplementedOpcode();
        },
        0x84 => {
            unimplementedOpcode();
        },
        0x85 => {
            unimplementedOpcode();
        },
        0x86 => {
            unimplementedOpcode();
        },
        0x87 => {
            unimplementedOpcode();
        },
        0x88 => {
            unimplementedOpcode();
        },
        0x89 => {
            unimplementedOpcode();
        },
        0x8a => {
            unimplementedOpcode();
        },
        0x8b => {
            unimplementedOpcode();
        },
        0x8c => {
            unimplementedOpcode();
        },
        0x8d => {
            unimplementedOpcode();
        },
        0x8e => {
            unimplementedOpcode();
        },
        0x8f => {
            unimplementedOpcode();
        },
        0x90 => {
            unimplementedOpcode();
        },
        0x91 => {
            unimplementedOpcode();
        },
        0x92 => {
            unimplementedOpcode();
        },
        0x93 => {
            unimplementedOpcode();
        },
        0x94 => {
            unimplementedOpcode();
        },
        0x95 => {
            unimplementedOpcode();
        },
        0x96 => {
            unimplementedOpcode();
        },
        0x97 => {
            unimplementedOpcode();
        },
        0x98 => {
            unimplementedOpcode();
        },
        0x99 => {
            unimplementedOpcode();
        },
        0x9a => {
            unimplementedOpcode();
        },
        0x9b => {
            unimplementedOpcode();
        },
        0x9c => {
            unimplementedOpcode();
        },
        0x9d => {
            unimplementedOpcode();
        },
        0x9e => {
            unimplementedOpcode();
        },
        0x9f => {
            unimplementedOpcode();
        },
        0xa0 => {
            unimplementedOpcode();
        },
        0xa1 => {
            unimplementedOpcode();
        },
        0xa2 => {
            unimplementedOpcode();
        },
        0xa3 => {
            unimplementedOpcode();
        },
        0xa4 => {
            unimplementedOpcode();
        },
        0xa5 => {
            unimplementedOpcode();
        },
        0xa6 => {
            unimplementedOpcode();
        },
        0xa7 => {
            unimplementedOpcode();
        },
        0xa8 => {
            unimplementedOpcode();
        },
        0xa9 => {
            unimplementedOpcode();
        },
        0xaa => {
            unimplementedOpcode();
        },
        0xab => {
            unimplementedOpcode();
        },
        0xac => {
            unimplementedOpcode();
        },
        0xad => {
            unimplementedOpcode();
        },
        0xae => {
            unimplementedOpcode();
        },
        0xaf => {
            unimplementedOpcode();
        },
        0xb0 => {
            unimplementedOpcode();
        },
        0xb1 => {
            unimplementedOpcode();
        },
        0xb2 => {
            unimplementedOpcode();
        },
        0xb3 => {
            unimplementedOpcode();
        },
        0xb4 => {
            unimplementedOpcode();
        },
        0xb5 => {
            unimplementedOpcode();
        },
        0xb6 => {
            unimplementedOpcode();
        },
        0xb7 => {
            unimplementedOpcode();
        },
        0xb8 => {
            unimplementedOpcode();
        },
        0xb9 => {
            unimplementedOpcode();
        },
        0xba => {
            unimplementedOpcode();
        },
        0xbb => {
            unimplementedOpcode();
        },
        0xbc => {
            unimplementedOpcode();
        },
        0xbd => {
            unimplementedOpcode();
        },
        0xbe => {
            unimplementedOpcode();
        },
        0xbf => {
            unimplementedOpcode();
        },
        0xc0 => {
            unimplementedOpcode();
        },
        0xc1 => {
            unimplementedOpcode();
        },
        0xc2 => {
            unimplementedOpcode();
        },
        0xc3 => {
            unimplementedOpcode();
        },
        0xc4 => {
            unimplementedOpcode();
        },
        0xc5 => {
            unimplementedOpcode();
        },
        0xc6 => {
            unimplementedOpcode();
        },
        0xc7 => {
            unimplementedOpcode();
        },
        0xc8 => {
            unimplementedOpcode();
        },
        0xc9 => {
            unimplementedOpcode();
        },
        0xca => {
            unimplementedOpcode();
        },
        0xcc => {
            unimplementedOpcode();
        },
        0xcd => {
            unimplementedOpcode();
        },
        0xce => {
            unimplementedOpcode();
        },
        0xcf => {
            unimplementedOpcode();
        },
        0xd0 => {
            unimplementedOpcode();
        },
        0xd1 => {
            unimplementedOpcode();
        },
        0xd2 => {
            unimplementedOpcode();
        },
        0xd3 => {
            unimplementedOpcode();
        },
        0xd4 => {
            unimplementedOpcode();
        },
        0xd5 => {
            unimplementedOpcode();
        },
        0xd6 => {
            unimplementedOpcode();
        },
        0xd7 => {
            unimplementedOpcode();
        },
        0xd8 => {
            unimplementedOpcode();
        },
        0xda => {
            unimplementedOpcode();
        },
        0xdb => {
            unimplementedOpcode();
        },
        0xdc => {
            unimplementedOpcode();
        },
        0xde => {
            unimplementedOpcode();
        },
        0xdf => {
            unimplementedOpcode();
        },
        0xe0 => {
            unimplementedOpcode();
        },
        0xe1 => {
            unimplementedOpcode();
        },
        0xe2 => {
            unimplementedOpcode();
        },
        0xe3 => {
            unimplementedOpcode();
        },
        0xe4 => {
            unimplementedOpcode();
        },
        0xe5 => {
            unimplementedOpcode();
        },
        0xe6 => {
            unimplementedOpcode();
        },
        0xe7 => {
            unimplementedOpcode();
        },
        0xe8 => {
            unimplementedOpcode();
        },
        0xe9 => {
            unimplementedOpcode();
        },
        0xea => {
            unimplementedOpcode();
        },
        0xeb => {
            unimplementedOpcode();
        },
        0xec => {
            unimplementedOpcode();
        },
        0xee => {
            unimplementedOpcode();
        },
        0xef => {
            unimplementedOpcode();
        },
        0xf0 => {
            unimplementedOpcode();
        },
        0xf1 => {
            unimplementedOpcode();
        },
        0xf2 => {
            unimplementedOpcode();
        },
        0xf3 => {
            unimplementedOpcode();
        },
        0xf4 => {
            unimplementedOpcode();
        },
        0xf5 => {
            unimplementedOpcode();
        },
        0xf6 => {
            unimplementedOpcode();
        },
        0xf7 => {
            unimplementedOpcode();
        },
        0xf8 => {
            unimplementedOpcode();
        },
        0xf9 => {
            unimplementedOpcode();
        },
        0xfa => {
            unimplementedOpcode();
        },
        0xfb => {
            unimplementedOpcode();
        },
        0xfc => {
            unimplementedOpcode();
        },
        0xfe => {
            unimplementedOpcode();
        },
        0xff => {
            unimplementedOpcode();
        },
        //NOPS
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x20, 0x18 => {
            cpu.pc += 1;
        },
    }
}

pub fn unimplementedOpcode() void {
    print("Unimplemented Opcode\n", .{});
}

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
            print("\x1b[0;34m{x:0>2}\x1b[0m     NOP", .{op});
            return 1;
        },
        0x01 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI B, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x02 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STAX B", .{op});
            return 1;
        },
        0x03 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX B", .{op});
            return 1;
        },
        0x04 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR B", .{op});
            return 1;
        },
        0x05 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR B", .{op});
            return 1;
        },
        0x06 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI B, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x07 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RLC", .{op});
            return 1;
        },
        0x09 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD B", .{op});
            return 1;
        },
        0x0a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     LDAX B", .{op});
            return 1;
        },
        0x0b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX B", .{op});
            return 1;
        },
        0x0c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR C", .{op});
            return 1;
        },
        0x0d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR C", .{op});
            return 1;
        },
        0x0e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI C, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x0f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RRC", .{op});
            return 1;
        },
        0x11 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI D, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x12 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STAX D", .{op});
            return 1;
        },
        0x13 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX D", .{op});
            return 1;
        },
        0x14 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR D", .{op});
            return 1;
        },
        0x15 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR D", .{op});
            return 1;
        },
        0x16 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI D,  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x17 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RAL", .{op});
            return 1;
        },
        0x19 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD D", .{op});
            return 1;
        },
        0x1a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     LDAX D", .{op});
            return 1;
        },
        0x1b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX D", .{op});
            return 1;
        },
        0x1c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR E", .{op});
            return 1;
        },
        0x1d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR E", .{op});
            return 1;
        },
        0x1e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI E, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x1f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RAR", .{op});
            return 1;
        },
        0x21 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI H, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x22 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m SHLD 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x23 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX H", .{op});
            return 1;
        },
        0x24 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR H", .{op});
            return 1;
        },
        0x25 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR H", .{op});
            return 1;
        },
        0x26 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI H, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x27 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAA", .{op});
            return 1;
        },
        0x29 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD H", .{op});
            return 1;
        },
        0x2a => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LHLD 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x2b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX H", .{op});
            return 1;
        },
        0x2c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR L", .{op});
            return 1;
        },
        0x2d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR L", .{op});
            return 1;
        },
        0x2e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI L,  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x2f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMA", .{op});
            return 1;
        },
        0x31 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LXI SP, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x32 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m STA 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x33 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INX SP", .{op});
            return 1;
        },
        0x34 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR M", .{op});
            return 1;
        },
        0x35 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR M", .{op});
            return 1;
        },
        0x36 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI M, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x37 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     STC", .{op});
            return 1;
        },
        0x39 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DAD SP", .{op});
            return 1;
        },
        0x3a => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m LDA 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x3b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCX SP", .{op});
            return 1;
        },
        0x3c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     INR A", .{op});
            return 1;
        },
        0x3d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DCR A", .{op});
            return 1;
        },
        0x3e => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   MVI A, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x3f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMC", .{op});
            return 1;
        },
        0x40 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,B", .{op});
            return 1;
        },
        0x41 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,C", .{op});
            return 1;
        },
        0x42 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,D", .{op});
            return 1;
        },
        0x43 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,E", .{op});
            return 1;
        },
        0x44 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,H", .{op});
            return 1;
        },
        0x45 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,L", .{op});
            return 1;
        },
        0x46 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,M", .{op});
            return 1;
        },
        0x47 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV B,A", .{op});
            return 1;
        },
        0x48 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,B", .{op});
            return 1;
        },
        0x49 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,C", .{op});
            return 1;
        },
        0x4a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,D", .{op});
            return 1;
        },
        0x4b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,E", .{op});
            return 1;
        },
        0x4c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,H", .{op});
            return 1;
        },
        0x4d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,L", .{op});
            return 1;
        },
        0x4e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,M", .{op});
            return 1;
        },
        0x4f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV C,A", .{op});
            return 1;
        },
        0x50 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,B", .{op});
            return 1;
        },
        0x51 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,C", .{op});
            return 1;
        },
        0x52 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,D", .{op});
            return 1;
        },
        0x53 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,E", .{op});
            return 1;
        },
        0x54 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,H", .{op});
            return 1;
        },
        0x55 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,L", .{op});
            return 1;
        },
        0x56 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,M", .{op});
            return 1;
        },
        0x57 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV D,A", .{op});
            return 1;
        },
        0x58 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,B", .{op});
            return 1;
        },
        0x59 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,C", .{op});
            return 1;
        },
        0x5a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,D", .{op});
            return 1;
        },
        0x5b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,E", .{op});
            return 1;
        },
        0x5c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,H", .{op});
            return 1;
        },
        0x5d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,L", .{op});
            return 1;
        },
        0x5e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,M", .{op});
            return 1;
        },
        0x5f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV E,A", .{op});
            return 1;
        },
        0x60 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,B", .{op});
            return 1;
        },
        0x61 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,C", .{op});
            return 1;
        },
        0x62 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,D", .{op});
            return 1;
        },
        0x63 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,E", .{op});
            return 1;
        },
        0x64 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,H", .{op});
            return 1;
        },
        0x65 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,L", .{op});
            return 1;
        },
        0x66 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,M", .{op});
            return 1;
        },
        0x67 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV H,A", .{op});
            return 1;
        },
        0x68 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,B", .{op});
            return 1;
        },
        0x69 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,C", .{op});
            return 1;
        },
        0x6a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,D", .{op});
            return 1;
        },
        0x6b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,E", .{op});
            return 1;
        },
        0x6c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,H", .{op});
            return 1;
        },
        0x6d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,L", .{op});
            return 1;
        },
        0x6e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,M", .{op});
            return 1;
        },
        0x6f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV L,A", .{op});
            return 1;
        },
        0x70 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,B", .{op});
            return 1;
        },
        0x71 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,C", .{op});
            return 1;
        },
        0x72 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,D", .{op});
            return 1;
        },
        0x73 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,E", .{op});
            return 1;
        },
        0x74 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,H", .{op});
            return 1;
        },
        0x75 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,L", .{op});
            return 1;
        },
        0x76 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     HLT", .{op});
            return 1;
        },
        0x77 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV M,A", .{op});
            return 1;
        },
        0x78 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,B", .{op});
            return 1;
        },
        0x79 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,C", .{op});
            return 1;
        },
        0x7a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,D", .{op});
            return 1;
        },
        0x7b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,E", .{op});
            return 1;
        },
        0x7c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,H", .{op});
            return 1;
        },
        0x7d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,L", .{op});
            return 1;
        },
        0x7e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,M", .{op});
            return 1;
        },
        0x7f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     MOV A,A", .{op});
            return 1;
        },
        0x80 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD B", .{op});
            return 1;
        },
        0x81 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD C", .{op});
            return 1;
        },
        0x82 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD D", .{op});
            return 1;
        },
        0x83 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD E", .{op});
            return 1;
        },
        0x84 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD H", .{op});
            return 1;
        },
        0x85 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD L", .{op});
            return 1;
        },
        0x86 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD M", .{op});
            return 1;
        },
        0x87 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADD A", .{op});
            return 1;
        },
        0x88 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC B", .{op});
            return 1;
        },
        0x89 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC C", .{op});
            return 1;
        },
        0x8a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC D", .{op});
            return 1;
        },
        0x8b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC E", .{op});
            return 1;
        },
        0x8c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC H", .{op});
            return 1;
        },
        0x8d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC L", .{op});
            return 1;
        },
        0x8e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC M", .{op});
            return 1;
        },
        0x8f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ADC A", .{op});
            return 1;
        },
        0x90 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB B", .{op});
            return 1;
        },
        0x91 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB C", .{op});
            return 1;
        },
        0x92 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB D", .{op});
            return 1;
        },
        0x93 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB E", .{op});
            return 1;
        },
        0x94 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB H", .{op});
            return 1;
        },
        0x95 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB L", .{op});
            return 1;
        },
        0x96 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB M", .{op});
            return 1;
        },
        0x97 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SUB A", .{op});
            return 1;
        },
        0x98 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB B", .{op});
            return 1;
        },
        0x99 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB C", .{op});
            return 1;
        },
        0x9a => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB D", .{op});
            return 1;
        },
        0x9b => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB E", .{op});
            return 1;
        },
        0x9c => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB H", .{op});
            return 1;
        },
        0x9d => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB L", .{op});
            return 1;
        },
        0x9e => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB M", .{op});
            return 1;
        },
        0x9f => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SBB A", .{op});
            return 1;
        },
        0xa0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA B", .{op});
            return 1;
        },
        0xa1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA C", .{op});
            return 1;
        },
        0xa2 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA D", .{op});
            return 1;
        },
        0xa3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA E", .{op});
            return 1;
        },
        0xa4 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA H", .{op});
            return 1;
        },
        0xa5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA L", .{op});
            return 1;
        },
        0xa6 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA M", .{op});
            return 1;
        },
        0xa7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ANA A", .{op});
            return 1;
        },
        0xa8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA B", .{op});
            return 1;
        },
        0xa9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA C", .{op});
            return 1;
        },
        0xaa => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA D", .{op});
            return 1;
        },
        0xab => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA E", .{op});
            return 1;
        },
        0xac => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA H", .{op});
            return 1;
        },
        0xad => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA L", .{op});
            return 1;
        },
        0xae => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA M", .{op});
            return 1;
        },
        0xaf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XRA A", .{op});
            return 1;
        },
        0xb0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA B", .{op});
            return 1;
        },
        0xb1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA C", .{op});
            return 1;
        },
        0xb2 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA D", .{op});
            return 1;
        },
        0xb3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA E", .{op});
            return 1;
        },
        0xb4 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA H", .{op});
            return 1;
        },
        0xb5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA L", .{op});
            return 1;
        },
        0xb6 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA M", .{op});
            return 1;
        },
        0xb7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     ORA A", .{op});
            return 1;
        },
        0xb8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP B", .{op});
            return 1;
        },
        0xb9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP C", .{op});
            return 1;
        },
        0xba => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP D", .{op});
            return 1;
        },
        0xbb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP E", .{op});
            return 1;
        },
        0xbc => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP H", .{op});
            return 1;
        },
        0xbd => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP L", .{op});
            return 1;
        },
        0xbe => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP M", .{op});
            return 1;
        },
        0xbf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     CMP A", .{op});
            return 1;
        },
        0xc0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RNZ", .{op});
            return 1;
        },
        0xc1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP B", .{op});
            return 1;
        },
        0xc2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JNZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc3 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JMP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CNZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH B", .{op});
            return 1;
        },
        0xc6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ADI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xc7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 0", .{op});
            return 1;
        },
        0xc8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RZ", .{op});
            return 1;
        },
        0xc9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RET", .{op});
            return 1;
        },
        0xca => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcd => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CALL 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xce => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ACI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xcf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 1", .{op});
            return 1;
        },
        0xd0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RNC", .{op});
            return 1;
        },
        0xd1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP D", .{op});
            return 1;
        },
        0xd2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JNC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd3 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   OUT  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xd4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CNC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH D", .{op});
            return 1;
        },
        0xd6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   SUI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xd7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 2", .{op});
            return 1;
        },
        0xd8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RC", .{op});
            return 1;
        },
        0xda => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xdb => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   IN  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xdc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xde => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   SBI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xdf => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 3", .{op});
            return 1;
        },
        0xe0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RPO", .{op});
            return 1;
        },
        0xe1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP H", .{op});
            return 1;
        },
        0xe2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JPO 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XTHL", .{op});
            return 1;
        },
        0xe4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CPO 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH H", .{op});
            return 1;
        },
        0xe6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ANI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xe7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 4", .{op});
            return 1;
        },
        0xe8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RPE", .{op});
            return 1;
        },
        0xe9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PCHL", .{op});
            return 1;
        },
        0xea => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JPE 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xeb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     XCHG", .{op});
            return 1;
        },
        0xec => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CPE 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xee => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   XRI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xef => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 5", .{op});
            return 1;
        },
        0xf0 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RP", .{op});
            return 1;
        },
        0xf1 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     POP PSW", .{op});
            return 1;
        },
        0xf2 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf3 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     DI", .{op});
            return 1;
        },
        0xf4 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf5 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     PUSH PSW", .{op});
            return 1;
        },
        0xf6 => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   ORI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xf7 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 6", .{op});
            return 1;
        },
        0xf8 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RM", .{op});
            return 1;
        },
        0xf9 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     SPHL", .{op});
            return 1;
        },
        0xfa => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m JM 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfb => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     EI", .{op});
            return 1;
        },
        0xfc => {
            print("\x1b[0;34m{x:0>2}{x:0>2}{x:0>2}\x1b[0m CM 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfe => {
            print("\x1b[0;34m{x:0>2}{x:0>2}\x1b[0m   CPI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xff => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RST 7", .{op});
            return 1;
        },
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x20, 0x18 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     NOP", .{op});
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

pub fn disassembleWholeProg(progBuf: []u8) void {
    var i: u16 = 0;
    while (i <= progBuf.len - 1) {
        print("0x{x:0>2}: ", .{i});
        var opSize = disassemble(progBuf, i);
        print("\n", .{});
        //opSize of zero means invalid op :/
        if (opSize == 0) {
            break;
        }
        i += opSize;
    }
}

pub fn initCpu(mem: []u8, alloc: std.mem.Allocator) !*CPU {
    // cflags all set to defaults above, no need to initialize
    var cflags = try alloc.create(CPUFlags);
    cflags.z = 1;
    cflags.s = 1;
    cflags.p = 1;
    cflags.cy = 1;
    cflags.ac = 1;
    cflags.pad = 1;

    var cpu = try alloc.create(CPU);
    cpu.a = 0;
    cpu.b = 0;
    cpu.c = 0;
    cpu.d = 0;
    cpu.e = 0;
    cpu.h = 0;
    cpu.l = 0;
    cpu.sp = 0;
    cpu.pc = 0;
    cpu.cc = cflags.*;
    cpu.memory = mem;
    return cpu;
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
        var mem = try readEmuFile(name, alloc);

        disassembleWholeProg(mem);
        var cpu = try initCpu(mem, alloc);
        cpu.pc = 0xbae;
        printCpuStatus(cpu);
        emulate(cpu);
        printCpuStatus(cpu);
    }
}
