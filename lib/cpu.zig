const std = @import("std");
const stdout = std.io.getStdOut();
const print = std.debug.print;

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
pub const CPU = struct {
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

pub fn disassembleCmd(pCpu: *CPU, args: [][]const u8) void {
    //Only way to implement local statics atm
    const Static = struct {
        var tmpPc: u16 = 0;
        var initialized: bool = false;
    };

    if (!Static.initialized) {
        Static.tmpPc = pCpu.pc;
        Static.initialized = true;
    }

    if (args.len == 1) {
        var i: u16 = 0;
        while (i < 8) : (i += 1) {
            _ = try stdout.writer().print("0x{x:0>2}: ", .{Static.tmpPc});
            Static.tmpPc += disassemble(pCpu.memory, Static.tmpPc);
            _ = try stdout.writer().write("\n");
        }
    } else {
        if (std.mem.eql(u8, args[1], "pc")) {
            Static.tmpPc = pCpu.pc;
            var i: u16 = 0;
            while (i < 8) : (i += 1) {
                _ = try stdout.writer().print("0x{x:0>2}: ", .{Static.tmpPc});
                Static.tmpPc += disassemble(pCpu.memory, Static.tmpPc);
                _ = try stdout.writer().write("\n");
            }
        } else {
            const addr: u16 = std.fmt.parseInt(u16, args[1], 0) catch blk: {
                try stdout.writer().print("\x1b[0;31mInvalid address: '{s}'\x1b[0m\n", .{args[1]});
                break :blk 0;
            };
            if (addr < 0 or addr > pCpu.memory.len) {
                try stdout.writer().print("\x1b[0;31mInvalid address: '{s}'\x1b[0m\n", .{args[1]});
                return;
            }
            Static.tmpPc = addr;

            var i: u16 = 0;
            while (i < 8) : (i += 1) {
                _ = try stdout.writer().print("0x{x:0>2}: ", .{Static.tmpPc});
                Static.tmpPc += disassemble(pCpu.memory, Static.tmpPc);
                _ = try stdout.writer().write("\n");
            }
        }
    }
}

pub fn printCpuCmd(pCpu: *CPU, args: [][]const u8) void {
    if (args.len == 1) {
        printCpuStatus(pCpu);
    } else {
        for (args[1..]) |reg| {
            const regBlk = if (reg.len == 1) regVal: {
                const ourReg: u16 = switch (reg[0]) {
                    'a' => pCpu.a,
                    'b' => pCpu.b,
                    'c' => pCpu.c,
                    'd' => pCpu.d,
                    'e' => pCpu.e,
                    'h' => pCpu.h,
                    'l' => pCpu.l,
                    else => {
                        stdout.writer().print("\x1b[0;31mInvalid register '{s}'\x1b[0m\n", .{reg}) catch {};
                        return;
                    },
                };
                break :regVal ourReg;
            } else regVal: {
                var retMe: u16 = 0;
                if (std.mem.eql(u8, reg, "pc")) {
                    retMe = pCpu.pc;
                } else if (std.mem.eql(u8, reg, "sp")) {
                    retMe = pCpu.sp;
                } else if (std.mem.eql(u8, reg, "bc")) {
                    retMe = pCpu.b;
                    retMe = retMe << 8;
                    retMe += pCpu.c;
                } else if (std.mem.eql(u8, reg, "de")) {
                    retMe = pCpu.d;
                    retMe = retMe << 8;
                    retMe += pCpu.e;
                } else if (std.mem.eql(u8, reg, "hl")) {
                    retMe = pCpu.h;
                    retMe = retMe << 8;
                    retMe += pCpu.l;
                } else if (std.mem.eql(u8, reg, "flags")) {
                    stdout.writer().print("z:{b} s:{b} p:{b} cy:{b} ac:{b}\n", .{ pCpu.cc.z, pCpu.cc.s, pCpu.cc.p, pCpu.cc.cy, pCpu.cc.ac }) catch {};
                    return;
                } else {
                    stdout.writer().print("\x1b[0;31mInvalid register '{s}'\x1b[0m\n", .{reg}) catch {};
                    return;
                }
                break :regVal retMe;
            };
            stdout.writer().print("{s}: 0x{x:0>2}\n", .{ reg, regBlk }) catch {};
        }
    }
}

pub fn parity(result: u16) u1 {
    if (result % 2 == 0) {
        return 1;
    }
    return 0;
}

pub fn printCpuStatus(pCpu: *CPU) void {
    var cpu = pCpu.*;
    print(" a: 0x{x:0>2} b: 0x{x:0>2} c: 0x{x:0>2}", .{ cpu.a, cpu.b, cpu.c });
    print(" d: 0x{x:0>2}\n e: 0x{x:0>2} h: 0x{x:0>2} l: 0x{x:0>2}\n", .{ cpu.d, cpu.e, cpu.h, cpu.l });
    print(" pc: 0x{x:0>4} -> [", .{cpu.pc});
    _ = disassemble(cpu.memory, cpu.pc);
    print("]\n sp: 0x{x:0>4} -> [0x{x:0>2}{x:0>2}]\n", .{ cpu.sp, cpu.memory[cpu.sp + 1], cpu.memory[cpu.sp] });
    print(" z:{b} s:{b} p:{b} cy:{b} ac:{b}", .{ cpu.cc.z, cpu.cc.s, cpu.cc.p, cpu.cc.cy, cpu.cc.ac });
    print("\n\n", .{});
}

///Func to emulate 8080 instructions
pub fn emulate(cpu: *CPU) void {
    @setRuntimeSafety(false);
    var op: []u8 = cpu.memory[cpu.pc..(cpu.pc + 3)];
    switch (op[0]) {
        0x00 => {
            //NOP
            cpu.pc += 1;
        },
        0x01 => {
            //LXI B, D16 (BC = D16)
            cpu.b = op[2];
            cpu.c = op[1];
            cpu.pc += 3;
        },
        0x02 => {
            //STAX B
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc += cpu.c;

            cpu.memory[bc] = cpu.a;
            cpu.pc += 1;
        },
        0x03 => {
            //INX B (BC = BC + 1)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc += cpu.c;

            bc += 1;

            cpu.b = @truncate(u8, (bc >> 8));
            cpu.c = @truncate(u8, bc);

            cpu.pc += 1;
        },
        0x04 => {
            //INR B (B = B + 1)
            var result: u16 = cpu.b;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.b = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x05 => {
            //DCR B (B = B - 1)
            var result: u16 = cpu.b;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.b = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x06 => {
            //MVI B, D8 (B = D8)
            cpu.b = op[1];
            cpu.pc += 2;
        },
        0x07 => {
            //RLC (A = (A << 1) | ((A & 0x80) >> 7) )
            var op1: u8 = cpu.a;
            var op2: u8 = (op1 & 0x80) >> 7;
            var result: u8 = (op1 << 1) | op2;
            cpu.a = result;
            cpu.cc.cy = @boolToInt(op2 == 1);
            cpu.pc += 1;
        },
        0x09 => {
            //DAD B (HL = HL + BC)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc += cpu.c;

            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            hl += bc;
            cpu.cc.cy = @boolToInt(((hl & 0x100) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc += 1;
        },
        0x0a => {
            //LDAX B (A = (BC))
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc += cpu.c;

            cpu.a = cpu.memory[bc];
            cpu.pc += 1;
        },
        0x0b => {
            //DCX B (BC = BC - 1)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc += cpu.c;
            bc -= 1;

            cpu.b = @truncate(u8, (bc >> 8));
            cpu.c = @truncate(u8, bc);
            cpu.pc += 1;
        },
        0x0c => {
            //INR C (C = C + 1)
            var result: u16 = cpu.c;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.c = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x0d => {
            //DCR C (C = C - 1)
            var result: u16 = cpu.c;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.c = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x0e => {
            //MVI C, D8 (C = D8)
            cpu.c = op[1];
            cpu.pc += 2;
        },
        0x0f => {
            //RRC (A = (A & 1 << 7) | (A >> 1) )
            var op1: u8 = cpu.a;
            var result: u8 = (op1 & 1 << 7) | (op1 >> 1);
            cpu.a = result;
            cpu.cc.cy = @boolToInt((op1 & 1) == 1);
            cpu.pc += 1;
        },
        0x11 => {
            //LXI D, D16 (DE = D16)
            cpu.d = op[2];
            cpu.e = op[1];
            cpu.pc += 3;
        },
        0x12 => {
            //STAX D
            var de: u16 = cpu.d;
            de = de << 8;
            de += cpu.e;

            cpu.memory[de] = cpu.a;
            cpu.pc += 1;
        },
        0x13 => {
            //INX D (DE = DE + 1)
            var de: u16 = cpu.d;
            de = de << 8;
            de += cpu.e;
            de += 1;

            cpu.d = @truncate(u8, (de >> 8));
            cpu.e = @truncate(u8, de);

            cpu.pc += 1;
        },
        0x14 => {
            //INR D (D = D + 1)
            var result: u16 = cpu.d;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.d = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x15 => {
            //DCR D (D = D - 1)
            var result: u16 = cpu.d;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.d = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x16 => {
            //MVI D, D8 (D = D8)
            cpu.d = op[1];
            cpu.pc += 2;
        },
        0x17 => {
            //RAL (A = (A << 1) | CY)
            var op1: u8 = cpu.a;
            var op2: u8 = @as(u8, cpu.cc.cy);
            var bit7: u8 = (op1 & 0x80) >> 7;
            var result: u8 = (op1 << 1) | op2;
            cpu.a = result;
            cpu.cc.cy = @boolToInt(bit7 == 1);
            cpu.pc += 1;
        },
        0x19 => {
            //DAD D (HL = HL + DE)
            var de: u16 = cpu.d;
            de = de << 8;
            de += cpu.e;

            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            hl += de;
            cpu.cc.cy = @boolToInt(((hl & 0x100) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc += 1;
        },
        0x1a => {
            //LDAX D (A = (DE))
            var de: u16 = cpu.d;
            de = de << 8;
            de += cpu.e;

            cpu.a = cpu.memory[de];
            cpu.pc += 1;
        },
        0x1b => {
            //DCX D (DE = DE - 1)
            var de: u16 = cpu.d;
            de = de << 8;
            de += cpu.e;
            de -= 1;

            cpu.d = @truncate(u8, (de >> 8));
            cpu.e = @truncate(u8, de);
            cpu.pc += 1;
        },
        0x1c => {
            //INR E (E = E + 1)
            var result: u16 = cpu.e;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.e = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x1d => {
            //DCR E (E = E - 1)
            var result: u16 = cpu.e;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.e = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x1e => {
            //MVI E, D8 (E = D8)
            cpu.e = op[1];
            cpu.pc += 2;
        },
        0x1f => {
            //RAR (A = (CY << 7) | (A >> 1) )
            var op1: u8 = cpu.a;
            var op2: u8 = @as(u8, cpu.cc.cy);
            var result: u8 = (op2 << 7) | (op1 >> 1);
            cpu.a = result;
            cpu.cc.cy = @boolToInt((op1 & 1) == 1);
            cpu.pc += 1;
        },
        0x20 => {
            //RIM
            unimplementedOpcode(op[0], cpu);
        },
        0x21 => {
            //LXI H, D16 (HL = D16)
            cpu.h = op[2];
            cpu.l = op[1];
            cpu.pc += 3;
        },
        0x22 => {
            //STAX H
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.memory[hl] = cpu.a;
            cpu.pc += 1;
        },
        0x23 => {
            //INX H (HL = HL + 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            hl += 1;

            cpu.h = @truncate(u8, (hl >> 8));
            cpu.l = @truncate(u8, hl);

            cpu.pc += 1;
        },
        0x24 => {
            //INR H (H = H + 1)
            var result: u16 = cpu.h;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.h = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x25 => {
            //DCR H (H = H - 1)
            var result: u16 = cpu.h;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.h = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x26 => {
            //MVI H, D8 (H = D8)
            cpu.h = op[1];
            cpu.pc += 2;
        },
        0x27 => {
            unimplementedOpcode(op[0], cpu);
        },
        0x29 => {
            //DAD H (HL = HL *= 2)
            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            hl = hl << 1;
            cpu.cc.cy = @boolToInt(((hl & 0x100) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc += 1;
        },
        0x2a => {
            //LDAX H (A = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.a = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x2b => {
            //DLX H (HL = HL - 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            hl -= 1;

            cpu.h = @truncate(u8, (hl >> 8));
            cpu.l = @truncate(u8, hl);
            cpu.pc += 1;
        },
        0x2c => {
            //INR L (L = L + 1)
            var result: u16 = cpu.l;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.l = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x2d => {
            //DCR L (L = L - 1)
            var result: u16 = cpu.l;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.l = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x2e => {
            //MVI L, D8 (L = D8)
            cpu.l = op[1];
            cpu.pc += 2;
        },
        0x2f => {
            //CMA (A = !A)
            cpu.a = ~cpu.a;
            cpu.pc += 1;
        },
        0x31 => {
            //LXI SP, D16 (SP = D16)
            var new_sp: u16 = op[2];
            new_sp = new_sp << 8;
            new_sp += op[1];
            cpu.sp = new_sp;
            cpu.pc += 3;
        },
        0x32 => {
            //STA addr ((addr) = A)
            var addr: u16 = op[2];
            addr = addr << 8;
            addr += op[1];

            cpu.memory[addr] = cpu.a;
        },
        0x33 => {
            //INX SP (SP = SP + 1)
            cpu.sp += 1;
            cpu.pc += 1;
        },
        0x34 => {
            //INR M ((HL) = (HL) + 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var result: u16 = cpu.memory[hl];
            result +%= 1;
            cpu.memory[hl] = @truncate(u8, result);

            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x35 => {
            //DCR M ((HL) = (HL) - 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var result: u16 = cpu.memory[hl];
            result -%= 1;
            cpu.memory[hl] = @truncate(u8, result);

            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x36 => {
            //MVI M, D8 ((HL) = D8)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.memory[hl] = op[1];
            cpu.pc += 2;
        },
        0x37 => {
            //STC
            cpu.cc.cy = 1;
        },
        0x39 => {
            //DAD SP (HL = HL + SP)
            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            hl += cpu.sp;
            cpu.cc.cy = @boolToInt(((hl & 0x100) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc += 1;
        },
        0x3a => {
            //LDA addr (A = (addr))
            var addr: u16 = op[2];
            addr = addr << 8;
            addr += op[1];

            cpu.a = cpu.memory[addr];
            cpu.pc += 3;
        },
        0x3b => {
            //DCX SP (SP = SP - 1)
            cpu.sp -= 1;
            cpu.pc += 1;
        },
        0x3c => {
            //INR A (A = A + 1)
            var result: u16 = cpu.a;
            result +%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.a = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x3d => {
            //DCR A (A = A + 1)
            var result: u16 = cpu.a;
            result -%= 1;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.a = @truncate(u8, result);
            cpu.pc += 1;
        },
        0x3e => {
            //MVI A, D8 (A = D8)
            cpu.a = op[1];
            cpu.pc += 2;
        },
        0x3f => {
            cpu.cc.cy = ~cpu.cc.cy;
        },
        0x40 => {
            //MOV B, B (B = B)
            cpu.b = cpu.b;
            cpu.pc += 1;
        },
        0x41 => {
            //MOV B, C (B = C)
            cpu.b = cpu.c;
            cpu.pc += 1;
        },
        0x42 => {
            //MOV B, D (B = D)
            cpu.b = cpu.d;
            cpu.pc += 1;
        },
        0x43 => {
            //MOV B, E (B = E)
            cpu.b = cpu.e;
            cpu.pc += 1;
        },
        0x44 => {
            //MOV B, H (B = H)
            cpu.b = cpu.h;
            cpu.pc += 1;
        },
        0x45 => {
            //MOV B, L (B = L)
            cpu.b = cpu.l;
            cpu.pc += 1;
        },
        0x46 => {
            //MOV B, M (B = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.b = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x47 => {
            //MOV B, A (B = A)
            cpu.b = cpu.a;
            cpu.pc += 1;
        },
        0x48 => {
            //MOV C, B (C = B)
            cpu.c = cpu.b;
            cpu.pc += 1;
        },
        0x49 => {
            //MOV C, C (C = C)
            cpu.c = cpu.c;
            cpu.pc += 1;
        },
        0x4a => {
            //MOV C, D (C = D)
            cpu.c = cpu.d;
            cpu.pc += 1;
        },
        0x4b => {
            //MOV C, E (C = E)
            cpu.c = cpu.e;
            cpu.pc += 1;
        },
        0x4c => {
            //MOV C, H (C = H)
            cpu.c = cpu.h;
            cpu.pc += 1;
        },
        0x4d => {
            //MOV C, L (C = L)
            cpu.c = cpu.l;
            cpu.pc += 1;
        },
        0x4e => {
            //MOV C, M (C = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.c = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x4f => {
            //MOV C, A (C = A)
            cpu.c = cpu.a;
            cpu.pc += 1;
        },
        0x50 => {
            //MOV D, B (D = B)
            cpu.d = cpu.b;
            cpu.pc += 1;
        },
        0x51 => {
            //MOV D, C (D = C)
            cpu.d = cpu.c;
            cpu.pc += 1;
        },
        0x52 => {
            //MOV D, D (D = D)
            cpu.d = cpu.d;
            cpu.pc += 1;
        },
        0x53 => {
            //MOV D, E (D = E)
            cpu.d = cpu.e;
            cpu.pc += 1;
        },
        0x54 => {
            //MOV D, H (D = H)
            cpu.d = cpu.h;
            cpu.pc += 1;
        },
        0x55 => {
            //MOV D, L (D = L)
            cpu.d = cpu.l;
            cpu.pc += 1;
        },
        0x56 => {
            //MOV D, M (D = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.d = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x57 => {
            //MOV D, A (D = A)
            cpu.d = cpu.a;
            cpu.pc += 1;
        },
        0x58 => {
            //MOV E, B (E = B)
            cpu.e = cpu.b;
            cpu.pc += 1;
        },
        0x59 => {
            //MOV E, C (E = C)
            cpu.e = cpu.c;
            cpu.pc += 1;
        },
        0x5a => {
            //MOV E, D (E = D)
            cpu.e = cpu.d;
            cpu.pc += 1;
        },
        0x5b => {
            //MOV E, E (E = E)
            cpu.e = cpu.e;
            cpu.pc += 1;
        },
        0x5c => {
            //MOV E, H (E = H)
            cpu.e = cpu.h;
            cpu.pc += 1;
        },
        0x5d => {
            //MOV E, L (E = L)
            cpu.e = cpu.l;
            cpu.pc += 1;
        },
        0x5e => {
            //MOV E, M (E = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.e = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x5f => {
            //MOV E, A (E = A)
            cpu.e = cpu.a;
            cpu.pc += 1;
        },
        0x60 => {
            //MOV H, B (H = B)
            cpu.h = cpu.b;
            cpu.pc += 1;
        },
        0x61 => {
            //MOV H, C (H = C)
            cpu.h = cpu.c;
            cpu.pc += 1;
        },
        0x62 => {
            //MOV H, D (H = D)
            cpu.h = cpu.d;
            cpu.pc += 1;
        },
        0x63 => {
            //MOV H, E (H = E)
            cpu.h = cpu.e;
            cpu.pc += 1;
        },
        0x64 => {
            //MOV H, H (H = H)
            cpu.h = cpu.h;
            cpu.pc += 1;
        },
        0x65 => {
            //MOV H, L (H = L)
            cpu.h = cpu.l;
            cpu.pc += 1;
        },
        0x66 => {
            //MOV H, M (H = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.h = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x67 => {
            //MOV H, A (H = A)
            cpu.h = cpu.a;
            cpu.pc += 1;
        },
        0x68 => {
            //MOV L, B (L = B)
            cpu.l = cpu.b;
            cpu.pc += 1;
        },
        0x69 => {
            //MOV L, C (L = C)
            cpu.l = cpu.c;
            cpu.pc += 1;
        },
        0x6a => {
            //MOV L, D (L = D)
            cpu.l = cpu.d;
            cpu.pc += 1;
        },
        0x6b => {
            //MOV L, E (L = E)
            cpu.l = cpu.e;
            cpu.pc += 1;
        },
        0x6c => {
            //MOV L, H (L = H)
            cpu.l = cpu.h;
            cpu.pc += 1;
        },
        0x6d => {
            //MOV L, L (L = L)
            cpu.l = cpu.l;
            cpu.pc += 1;
        },
        0x6e => {
            //MOV L, M (L = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.l = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x6f => {
            //MOV L, A (L = A)
            cpu.l = cpu.a;
            cpu.pc += 1;
        },
        0x70 => {
            //MOV M, B ((HL) = B)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.b;
            cpu.pc += 1;
        },
        0x71 => {
            //MOV M, C ((HL) = C)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.c;
            cpu.pc += 1;
        },
        0x72 => {
            //MOV M, D ((HL) = D)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.d;
            cpu.pc += 1;
        },
        0x73 => {
            //MOV M, E ((HL) = E)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.e;
            cpu.pc += 1;
        },
        0x74 => {
            //MOV M, H ((HL) = H)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.h;
            cpu.pc += 1;
        },
        0x75 => {
            //MOV M, L ((HL) = L)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.l;
            cpu.pc += 1;
        },
        0x76 => {
            unimplementedOpcode(op[0], cpu);
        },
        0x77 => {
            //MOV M, A ((HL) = A)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;
            cpu.memory[hl] = cpu.a;
            cpu.pc += 1;
        },
        0x78 => {
            //MOV A, B (A = B)
            cpu.l = cpu.a;
            cpu.pc += 1;
        },
        0x79 => {
            //MOV A, C (A = C)
            cpu.l = cpu.b;
            cpu.pc += 1;
        },
        0x7a => {
            //MOV A, D (A = D)
            cpu.l = cpu.c;
            cpu.pc += 1;
        },
        0x7b => {
            //MOV A, E (A = E)
            cpu.l = cpu.d;
            cpu.pc += 1;
        },
        0x7c => {
            //MOV A, H (A = H)
            cpu.l = cpu.h;
            cpu.pc += 1;
        },
        0x7d => {
            //MOV A, L (A = L)
            cpu.l = cpu.l;
            cpu.pc += 1;
        },
        0x7e => {
            //MOV A, M (A = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            cpu.l = cpu.memory[hl];
            cpu.pc += 1;
        },
        0x7f => {
            //MOV A, A (A = A)
            cpu.l = cpu.a;
            cpu.pc += 1;
        },
        0x80 => {
            //ADD B (A = A + B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x81 => {
            //ADD C (A = A + C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x82 => {
            //ADD D (A = A + D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x83 => {
            //ADD E (A = A + E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x84 => {
            //ADD H (A = A + H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x85 => {
            //ADD L (A = A + L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x86 => {
            //ADD M (A = A + (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x87 => {
            //ADD A (A = A + A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x88 => {
            //ADC B (A = A + B + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x89 => {
            //ADC C (A = A + C + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8a => {
            //ADC D (A = A + D + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8b => {
            //ADC E (A = A + E + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8c => {
            //ADC H (A = A + H + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8d => {
            //ADC L (A = A + L + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8e => {
            //ADC M (A = A + (HL) + CY)
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x8f => {
            //ADC A (A = A + A + CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x90 => {
            //SUB B (A = A - B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x91 => {
            //SUB C (A = A - C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x92 => {
            //SUB D (A = A - D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x93 => {
            //SUB E (A = A - E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x94 => {
            //SUB H (A = A - H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x95 => {
            //SUB L (A = A - L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x96 => {
            //SUB M (A = A - (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x97 => {
            //SUB A (A = A - A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x98 => {
            //SBB B (A = A - B - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x99 => {
            //SBB C (A = A - C - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9a => {
            //SBB D (A = A - D - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9b => {
            //SBB E (A = A - E - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9c => {
            //SBB H (A = A - H - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9d => {
            //SBB L (A = A - L - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9e => {
            //SBB M (A = A - (HL) - CY)
            //Dereference loc of HL
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0x9f => {
            //SBB A (A = A - A - CY)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa0 => {
            //ANA B (A = A & B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa1 => {
            //ANA C (A = A & C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa2 => {
            //ANA D (A = A & D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa3 => {
            //ANA E (A = A & E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa4 => {
            //ANA H (A = A & H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa5 => {
            //ANA L (A = A & L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa6 => {
            //ANA M (A = A & (HL))
            //Dereference loc of HL
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa7 => {
            //ANA A (A = A & A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa8 => {
            //XRA B (A = A ^ B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xa9 => {
            //XRA C (A = A ^ C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xaa => {
            //XRA D (A = A ^ D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xab => {
            //XRA E (A = A ^ E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xac => {
            //XRA H (A = A ^ H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xad => {
            //XRA L (A = A ^ L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xae => {
            //XRA M (A = A ^ (HL))
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xaf => {
            //XRA A (A = A ^ A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb0 => {
            //ORA B (A = A | B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb1 => {
            //ORA C (A = A | C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb2 => {
            //ORA D (A = A | D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb3 => {
            //ORA E (A = A | E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.e;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb4 => {
            //ORA H (A = A | H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb5 => {
            //ORA L (A = A | L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb6 => {
            //ORA M (A = A | (HL))
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb7 => {
            //ORA A (A = A | A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb8 => {
            //CMP B (FLAGS = A - B)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xb9 => {
            //CMP C (FLAGS = A - C)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.b;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xba => {
            //CMP D (FLAGS = A - D)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.c;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xbb => {
            //CMP E (FLAGS = A - E)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.d;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xbc => {
            //CMP H (FLAGS = A - H)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.h;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xbd => {
            //CMP L (FLAGS = A - L)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.l;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xbe => {
            //CMP M (FLAGS = A - (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl += cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xbf => {
            //CMP A (FLAGS = A - A)
            var op1: u16 = cpu.a;
            var op2: u16 = cpu.a;
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xc0 => {
            //RNZ
            if (cpu.cc.z == 0) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xc1 => {
            //POP B (C = (SP), B = (SP +1), SP += 2)
            cpu.c = cpu.memory[cpu.sp];
            cpu.b = cpu.memory[cpu.sp + 1];
            cpu.sp += 2;
            cpu.pc += 1;
        },
        0xc2 => {
            //JNZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.z == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xc3 => {
            //JMP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc = jmp_to;
        },
        0xc4 => {
            //CNZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.z == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xc5 => {
            //PUSH B ((SP-1) = B, (SP-2) = C, SP -= 2)
            cpu.memory[cpu.sp - 1] = cpu.b;
            cpu.memory[cpu.sp - 2] = cpu.c;
            cpu.sp -= 2;
            cpu.pc += 1;
        },
        0xc6 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xc7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xc8 => {
            //RZ
            if (cpu.cc.z == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xc9 => {
            //RET
            var jmp_to: u16 = cpu.memory[cpu.sp + 1];
            jmp_to = jmp_to << 8;
            jmp_to += cpu.memory[cpu.sp];

            //Increment SP, jump
            cpu.sp += 2;
            cpu.pc = jmp_to;
        },
        0xca => {
            //JZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.z == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xcc => {
            //CZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.z == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xcd => {
            //CALL addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            //Write ret addr
            cpu.pc += 3;
            cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
            cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
            //Decrement SP, jump
            cpu.sp -= 2;
            cpu.pc = jmp_to;
        },
        0xce => {
            unimplementedOpcode(op[0], cpu);
        },
        0xcf => {
            unimplementedOpcode(op[0], cpu);
        },
        0xd0 => {
            //RNC
            if (cpu.cc.cy == 0) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xd1 => {
            //POP D (E = (SP), D = (SP +1), SP += 2)
            cpu.e = cpu.memory[cpu.sp];
            cpu.d = cpu.memory[cpu.sp + 1];
            cpu.sp += 2;
            cpu.pc += 1;
        },
        0xd2 => {
            //JNC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.cy == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xd3 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xd4 => {
            //CNC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.cy == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xd5 => {
            //PUSH D ((SP-1) = D, (SP-2) = E, SP -= 2)
            cpu.memory[cpu.sp - 1] = cpu.d;
            cpu.memory[cpu.sp - 2] = cpu.e;
            cpu.sp -= 2;
            cpu.pc += 1;
        },
        0xd6 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xd7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xd8 => {
            //RC
            if (cpu.cc.cy == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xda => {
            //JC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.cy == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xdb => {
            unimplementedOpcode(op[0], cpu);
        },
        0xdc => {
            //CC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.cy == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xde => {
            unimplementedOpcode(op[0], cpu);
        },
        0xdf => {
            unimplementedOpcode(op[0], cpu);
        },
        0xe0 => {
            //RPO
            if (cpu.cc.p == 0) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xe1 => {
            //POP H (L = (SP), H = (SP +1), SP += 2)
            cpu.l = cpu.memory[cpu.sp];
            cpu.h = cpu.memory[cpu.sp + 1];
            cpu.sp += 2;
            cpu.pc += 1;
        },
        0xe2 => {
            //JPO addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.p == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xe3 => {
            //XTHL
            var h: u8 = cpu.h;
            var l: u8 = cpu.l;
            var sp1: u8 = cpu.memory[cpu.sp];
            var sp2: u8 = cpu.memory[cpu.sp + 1];

            cpu.h = sp2;
            cpu.l = sp1;
            cpu.memory[cpu.sp] = l;
            cpu.memory[cpu.sp + 1] = h;
            cpu.pc += 1;
        },
        0xe4 => {
            //CPO addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.p == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xe5 => {
            //PUSH H ((SP-1) = H, (SP-2) = L, SP -= 2)
            cpu.memory[cpu.sp - 1] = cpu.h;
            cpu.memory[cpu.sp - 2] = cpu.l;
            cpu.sp -= 2;
            cpu.pc += 1;
        },
        0xe6 => {
            //ANI D8 (A = A & D8)
            var op1: u16 = cpu.a;
            var op2: u16 = op[1];
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            //ANI clears carry bit
            cpu.cc.cy = 0;
            cpu.cc.p = parity(result);
            cpu.pc += 2;
        },
        0xe7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xe8 => {
            //RPE
            if (cpu.cc.p == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xe9 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xea => {
            //JPE addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.p == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xeb => {
            unimplementedOpcode(op[0], cpu);
        },
        0xec => {
            //CPE addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.p == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xee => {
            unimplementedOpcode(op[0], cpu);
        },
        0xef => {
            unimplementedOpcode(op[0], cpu);
        },
        0xf0 => {
            //RP
            if (cpu.cc.s == 0) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xf1 => {
            //POP PSW (FLAGS = (SP), A = (SP +1), SP += 2)
            var flags: u8 = cpu.memory[cpu.sp];
            cpu.cc.z = @boolToInt((flags & 1) == 1);
            cpu.cc.s = @boolToInt((flags & 2) == 2);
            cpu.cc.p = @boolToInt((flags & 4) == 4);
            cpu.cc.cy = @boolToInt((flags & 8) == 8);
            cpu.cc.ac = @boolToInt((flags & 16) == 16);

            cpu.a = cpu.memory[cpu.sp + 1];
            cpu.sp += 2;
            cpu.pc += 1;
        },
        0xf2 => {
            //JP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.s == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xf3 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xf4 => {
            //CP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.s == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xf5 => {
            //PUSH PSW ((SP-2) = FLAGS, (SP-1) = A, SP -= 2)
            var flags: u8 = 0;
            flags = (flags | cpu.cc.ac) << 4;
            flags = (flags | cpu.cc.cy) << 3;
            flags = (flags | cpu.cc.p) << 2;
            flags = (flags | cpu.cc.s) << 1;
            flags = flags | cpu.cc.z;

            cpu.memory[cpu.sp - 2] = flags;
            cpu.memory[cpu.sp - 1] = cpu.a;
            cpu.sp -= 2;
            cpu.pc += 1;
        },
        0xf6 => {
            //ORI D8 (A = A | D8)
            cpu.a = cpu.a | op[1];
            cpu.pc += 2;
        },
        0xf7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xf8 => {
            //RM
            if (cpu.cc.s == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to += cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp += 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 1;
            }
        },
        0xf9 => {
            //SPHL (SP = HL)
            var new_sp: u16 = cpu.h;
            new_sp = new_sp << 8;
            new_sp += cpu.l;
            cpu.sp = new_sp;
            cpu.pc += 1;
        },
        0xfa => {
            //JM addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];

            if (cpu.cc.s == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc += 3;
            }
        },
        0xfb => {
            unimplementedOpcode(op[0], cpu);
        },
        0xfc => {
            //CM addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to += op[1];
            cpu.pc += 3;
            if (cpu.cc.s == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -= 2;
                cpu.pc = jmp_to;
            }
        },
        0xfe => {
            //CPI D8 (A - D8)
            var result: u16 = cpu.a -% op[1];
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc += 1;
        },
        0xff => {
            //RST 7 (CALL 0x38)
            var jmp_to: u16 = 0x38;
            cpu.pc += 1;
            cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
            cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
            //Decrement SP, jump
            cpu.sp -= 2;
            cpu.pc = jmp_to;
        },
        //NOPS
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x18 => {
            cpu.pc += 1;
        },
    }
}

pub fn unimplementedOpcode(op: u8, cpu: *CPU) void {
    print("Unimplemented Opcode 0x{x:0>2} (", .{op});
    _ = disassemble(cpu.memory, cpu.pc);
    print(")\n", .{});
    std.os.exit(1);
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
        0x20 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     RIM", .{op});
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
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x18 => {
            print("\x1b[0;34m{x:0>2}\x1b[0m     NOP", .{op});
            return 1;
        },
    }
    return 0;
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

//pub fn initMemory(usize , alloc: std.mem.Allocator) ![]u8{
//
//}

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
