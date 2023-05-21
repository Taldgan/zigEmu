const colors = @import("colors.zig");
const std = @import("std");
const stdout = std.io.getStdOut();
const print = std.debug.print;

pub const mem_size = 0x10000;

// Struct representing flags register state
const CPUFlags = struct {
    z: u1 = 0,
    s: u1 = 0,
    p: u1 = 0,
    cy: u1 = 0,
    ac: u1 = 0,
    pad: u1 = 0,
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
    cpm_hook: bool,
    status_print: bool,
};

pub fn statusPrintCmd(pCpu: *CPU, args: [][]const u8) void {
    _ = args;
    if (pCpu.status_print) {
        pCpu.status_print = false;
        _ = stdout.writer().write(colors.GREEN ++ "Print CPU Status on Step Disabled" ++ colors.DEFAULT ++ "\n") catch {};
    }
    else {
        pCpu.status_print = true;
        _ = stdout.writer().write(colors.GREEN ++ "Print CPU Status on Step Enabled" ++ colors.DEFAULT ++ "\n") catch {};
    }
}

pub fn cpmHookCmd(pCpu: *CPU, args: [][]const u8) void {
    _ = args;
    if (pCpu.cpm_hook) {
        pCpu.cpm_hook = false;
        _ = stdout.writer().write(colors.GREEN ++ "CP/M OS Hook Disabled" ++ colors.DEFAULT ++ "\n") catch {};
    }
    else {
        pCpu.cpm_hook = true;
        _ = stdout.writer().write(colors.GREEN ++ "CP/M OS Hook Enabled" ++ colors.DEFAULT ++ "\n") catch {};
    }
}

pub fn loadCmd(pCpu: *CPU, args: [][]const u8) void {
    var mapLoc: u16 = 0;
    if (args.len < 2) {
        _ = stdout.writer().print(colors.RED ++ "Need a file for load" ++ colors.DEFAULT ++ "\n", .{}) catch {};
        return;
    }
    if (args.len > 2) {
        mapLoc = std.fmt.parseInt(u16, args[2], 0) catch blk: {
            _ = stdout.writer().print(colors.RED ++ "Invalid number of steps: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
            break :blk 0;
        };
    }
    const cwd = std.fs.cwd();
    var file = cwd.openFile(args[1], .{}) catch {
        stdout.writer().print(colors.RED ++ "Unable to open file '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
        return;
    };
    defer file.close();
    var fileBuf: [mem_size]u8 = undefined;

    const bytesRead = file.readAll(&fileBuf) catch {
        stdout.writer().print(colors.RED ++ "Unable to read file '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
        return;
    };

    if (bytesRead > mem_size) {
        stdout.writer().print(colors.RED ++ "Unable to read file '{s}' into memory  - file too large" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
        return;
    } else if (bytesRead + mapLoc > mem_size) {
        stdout.writer().print(colors.RED ++ "Unable to read file '{s}' into memory  - file too large at offset 0x{x:0>4}" ++ colors.DEFAULT ++ "\n", .{ args[1], mapLoc }) catch {};
        return;
    }

    //Copy bytes into cpu memory
    for (&fileBuf) |byte, i| {
        pCpu.memory[i+mapLoc] = byte;
        if (i >= bytesRead)
            break;
    }

    //PC should be set to location of mapped code
    pCpu.pc = mapLoc;

    _ = stdout.writer().print("\x1b[0;32mMapped file '{s}' into memory at address 0x{x:0>4}" ++ colors.DEFAULT ++ "\n", .{ args[1], mapLoc }) catch {};
}

pub fn stepCmd(pCpu: *CPU, args: [][]const u8) void {
    if (args.len == 1) {
        emulate(pCpu);
    } else {
        const steps: u32 = std.fmt.parseInt(u32, args[1], 0) catch blk: {
            _ = stdout.writer().print(colors.RED ++ "Invalid number of steps: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
            break :blk 0;
        };
        var i: u32 = 0;
        while (i < steps) : (i += 1) {
            emulate(pCpu);
        }
    }
    if (pCpu.status_print) {
        printCpuStatus(pCpu);
    }
    stdout.writer().print("0x{x:0>2}: ", .{pCpu.pc}) catch {};
    _ = disassemble(pCpu.memory, pCpu.pc);
    _ = stdout.writer().write("\n") catch {};
}

pub fn disassembleCmd(pCpu: *CPU, args: [][]const u8) void {
    //Only way to implement local statics atm
    const Static = struct {
        var tmp_pc: u16 = 0;
        var initialized: bool = false;
    };

    if (!Static.initialized) {
        Static.tmp_pc = pCpu.pc;
        Static.initialized = true;
    }

    if (args.len == 1) {
        var i: u16 = 0;
        while (i < 8) : (i += 1) {
            _ = stdout.writer().print("0x{x:0>2}: ", .{Static.tmp_pc}) catch {};
            Static.tmp_pc += disassemble(pCpu.memory, Static.tmp_pc);
            _ = stdout.writer().write("\n") catch {};
        }
    } else {
        if (std.mem.eql(u8, args[1], "pc")) {
            Static.tmp_pc = pCpu.pc;
            var i: u16 = 0;
            while (i < 8) : (i += 1) {
                _ = stdout.writer().print("0x{x:0>2}: ", .{Static.tmp_pc}) catch {};
                Static.tmp_pc += disassemble(pCpu.memory, Static.tmp_pc);
                _ = stdout.writer().write("\n") catch {};
            }
        } else {
            const addr: u16 = std.fmt.parseInt(u16, args[1], 0) catch blk: {
                stdout.writer().print(colors.RED ++ "Invalid address: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
                break :blk 0;
            };
            if (addr < 0 or addr > pCpu.memory.len) {
                stdout.writer().print(colors.RED ++ "Invalid address: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
                return;
            }
            Static.tmp_pc = addr;

            var i: u16 = 0;
            while (i < 8) : (i += 1) {
                _ = stdout.writer().print("0x{x:0>2}: ", .{Static.tmp_pc}) catch {};
                Static.tmp_pc += disassemble(pCpu.memory, Static.tmp_pc);
                _ = stdout.writer().write("\n") catch {};
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
                        stdout.writer().print(colors.RED ++ "Invalid register '{s}'" ++ colors.DEFAULT ++ "\n", .{reg}) catch {};
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
                    stdout.writer().print(colors.RED ++ "Invalid register '{s}'" ++ colors.DEFAULT ++ "\n", .{reg}) catch {};
                    return;
                }
                break :regVal retMe;
            };
            stdout.writer().print("{s}: 0x{x:0>2}\n", .{ reg, regBlk }) catch {};
        }
    }
}

pub fn parity(result: u16) u1 {
    return @boolToInt(result % 2 != 0);
}

pub fn printCpuStatus(pCpu: *CPU) void {
    var bc: u16 = pCpu.b;
    bc = bc << 8;
    bc +%= pCpu.c;
    var de: u16 = pCpu.d;
    de = de << 8;
    de +%= pCpu.e;
    var hl: u17 = pCpu.h;
    hl = hl << 8;
    hl +%= pCpu.l;

    var cpu = pCpu.*;
    print(" a: 0x{x:0>2} b: 0x{x:0>2} c: 0x{x:0>2}", .{ cpu.a, cpu.b, cpu.c });
    print(" d: 0x{x:0>2}\n e: 0x{x:0>2} h: 0x{x:0>2} l: 0x{x:0>2}\n", .{ cpu.d, cpu.e, cpu.h, cpu.l });
    print(" pc: 0x{x:0>4} -> [", .{cpu.pc});
    _ = disassemble(cpu.memory, cpu.pc);
    print("]\n bc: 0x{x:0>4} de: 0x{x:0>4} hl: 0x{x:0>4} -> [0x{x:0>2}]\n", .{ bc, de, hl, cpu.memory[hl]});
    print(" sp: 0x{x:0>4} -> [0x{x:0>2}{x:0>2}]\n", .{ cpu.sp, cpu.memory[cpu.sp + 1], cpu.memory[cpu.sp] });
    print(" z:{b} s:{b} p:{b} cy:{b} ac:{b}\n", .{ cpu.cc.z, cpu.cc.s, cpu.cc.p, cpu.cc.cy, cpu.cc.ac });
    if (pCpu.cpm_hook) {
        print(colors.GREEN ++ " CP/M Hook On\n" ++ colors.DEFAULT, .{});
    }
    if (pCpu.status_print) {
        print(colors.GREEN ++ " Step Status Print On\n" ++ colors.DEFAULT, .{});
    }
    print("\n", .{});
}

///Func to emulate 8080 instructions
pub fn emulate(cpu: *CPU) void {
    @setRuntimeSafety(false);
    var op: []u8 = cpu.memory[cpu.pc..(cpu.pc + 3)];
    switch (op[0]) {
        0x00 => {
            //NOP
            cpu.pc +%= 1;
        },
        0x01 => {
            //LXI B, D16 (BC = D16)
            cpu.b = op[2];
            cpu.c = op[1];
            cpu.pc +%= 3;
        },
        0x02 => {
            //STAX B ((BE) = A)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc +%= cpu.c;

            cpu.memory[bc] = cpu.a;
            cpu.pc +%= 1;
        },
        0x03 => {
            //INX B (BC = BC + 1)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc +%= cpu.c;

            bc +%= 1;

            cpu.b = @truncate(u8, (bc >> 8));
            cpu.c = @truncate(u8, bc);

            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x06 => {
            //MVI B, D8 (B = D8)
            cpu.b = op[1];
            cpu.pc +%= 2;
        },
        0x07 => {
            //RLC (A = (A << 1) | ((A & 0x80) >> 7) )
            var op1: u8 = cpu.a;
            var op2: u8 = (op1 & 0x80) >> 7;
            var result: u8 = (op1 << 1) | op2;
            cpu.a = result;
            cpu.cc.cy = @boolToInt(op2 == 1);
            cpu.pc +%= 1;
        },
        0x09 => {
            //DAD B (HL = HL + BC)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc +%= cpu.c;

            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            hl +%= bc;
            cpu.cc.cy = @boolToInt(((hl & 0x10000) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc +%= 1;
        },
        0x0a => {
            //LDAX B (A = (BC))
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc +%= cpu.c;

            cpu.a = cpu.memory[bc];
            cpu.pc +%= 1;
        },
        0x0b => {
            //DCX B (BC = BC - 1)
            var bc: u16 = cpu.b;
            bc = bc << 8;
            bc +%= cpu.c;
            bc -%= 1;

            cpu.b = @truncate(u8, (bc >> 8));
            cpu.c = @truncate(u8, bc);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x0e => {
            //MVI C, D8 (C = D8)
            cpu.c = op[1];
            cpu.pc +%= 2;
        },
        0x0f => {
            //RRC (A = (A & 1 << 7) | (A >> 1) )
            var op1: u8 = cpu.a;
            var result: u8 = (op1 & 1 << 7) | (op1 >> 1);
            cpu.a = result;
            cpu.cc.cy = @boolToInt((op1 & 1) == 1);
            cpu.pc +%= 1;
        },
        0x11 => {
            //LXI D, D16 (DE = D16)
            cpu.d = op[2];
            cpu.e = op[1];
            cpu.pc +%= 3;
        },
        0x12 => {
            //STAX D ((DE) = A)
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;

            cpu.memory[de] = cpu.a;
            cpu.pc +%= 1;
        },
        0x13 => {
            //INX D (DE = DE + 1)
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;
            de +%= 1;

            cpu.d = @truncate(u8, (de >> 8));
            cpu.e = @truncate(u8, de);

            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x16 => {
            //MVI D, D8 (D = D8)
            cpu.d = op[1];
            cpu.pc +%= 2;
        },
        0x17 => {
            //RAL (A = (A << 1) | CY)
            var op1: u8 = cpu.a;
            var op2: u8 = @as(u8, cpu.cc.cy);
            var bit7: u8 = (op1 & 0x80) >> 7;
            var result: u8 = (op1 << 1) | op2;
            cpu.a = result;
            cpu.cc.cy = @boolToInt(bit7 == 1);
            cpu.pc +%= 1;
        },
        0x19 => {
            //DAD D (HL = HL + DE)
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;

            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            hl +%= de;
            cpu.cc.cy = @boolToInt(((hl & 0x10000) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc +%= 1;
        },
        0x1a => {
            //LDAX D (A = (DE))
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;

            cpu.a = cpu.memory[de];
            cpu.pc +%= 1;
        },
        0x1b => {
            //DCX D (DE = DE - 1)
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;
            de -%= 1;

            cpu.d = @truncate(u8, (de >> 8));
            cpu.e = @truncate(u8, de);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x1e => {
            //MVI E, D8 (E = D8)
            cpu.e = op[1];
            cpu.pc +%= 2;
        },
        0x1f => {
            //RAR (A = (CY << 7) | (A >> 1) )
            var op1: u8 = cpu.a;
            var op2: u8 = @as(u8, cpu.cc.cy);
            var result: u8 = (op2 << 7) | (op1 >> 1);
            cpu.a = result;
            cpu.cc.cy = @boolToInt((op1 & 1) == 1);
            cpu.pc +%= 1;
        },
        0x20 => {
            //RIM
            unimplementedOpcode(op[0], cpu);
        },
        0x21 => {
            //LXI H, D16 (HL = D16)
            cpu.h = op[2];
            cpu.l = op[1];
            cpu.pc +%= 3;
        },
        0x22 => {
            //STAX H ((HL) = A)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.memory[hl] = cpu.a;
            cpu.pc +%= 1;
        },
        0x23 => {
            //INX H (HL = HL + 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            hl +%= 1;

            cpu.h = @truncate(u8, (hl >> 8));
            cpu.l = @truncate(u8, hl);

            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x26 => {
            //MVI H, D8 (H = D8)
            cpu.h = op[1];
            cpu.pc +%= 2;
        },
        0x27 => {
            unimplementedOpcode(op[0], cpu);
        },
        0x29 => {
            //DAD H (HL = HL *%= 2)
            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            hl = hl << 1;
            cpu.cc.cy = @boolToInt(((hl & 0x10000) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc +%= 1;
        },
        0x2a => {
            //LHLD H (A = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.a = cpu.memory[hl];
            cpu.pc +%= 3;
        },
        0x2b => {
            //DCX H (HL = HL - 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            hl -%= 1;

            cpu.h = @truncate(u8, (hl >> 8));
            cpu.l = @truncate(u8, hl);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x2e => {
            //MVI L, D8 (L = D8)
            cpu.l = op[1];
            cpu.pc +%= 2;
        },
        0x2f => {
            //CMA (A = !A)
            cpu.a = ~cpu.a;
            cpu.pc +%= 1;
        },
        0x31 => {
            //LXI SP, D16 (SP = D16)
            var new_sp: u16 = op[2];
            new_sp = new_sp << 8;
            new_sp +%= op[1];
            cpu.sp = new_sp;
            cpu.pc +%= 3;
        },
        0x32 => {
            //STA addr ((addr) = A)
            var addr: u16 = op[2];
            addr = addr << 8;
            addr +%= op[1];

            cpu.memory[addr] = cpu.a;
            cpu.pc +%= 3;
        },
        0x33 => {
            //INX SP (SP = SP + 1)
            cpu.sp +%= 1;
            cpu.pc +%= 1;
        },
        0x34 => {
            //INR M ((HL) = (HL) + 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var result: u16 = cpu.memory[hl];
            result +%= 1;
            cpu.memory[hl] = @truncate(u8, result);

            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
        },
        0x35 => {
            //DCR M ((HL) = (HL) - 1)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var result: u16 = cpu.memory[hl];
            result -%= 1;
            cpu.memory[hl] = @truncate(u8, result);

            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
        },
        0x36 => {
            //MVI M, D8 ((HL) = D8)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.memory[hl] = op[1];
            cpu.pc +%= 2;
        },
        0x37 => {
            //STC
            cpu.cc.cy = 1;
        },
        0x39 => {
            //DAD SP (HL = HL + SP)
            var hl: u17 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            hl +%= cpu.sp;
            cpu.cc.cy = @boolToInt(((hl & 0x10000) != 0));
            cpu.h = @truncate(u8, hl >> 8);
            cpu.l = @truncate(u8, hl);
            cpu.pc +%= 1;
        },
        0x3a => {
            //LDA addr (A = (addr))
            var addr: u16 = op[2];
            addr = addr << 8;
            addr +%= op[1];

            cpu.a = cpu.memory[addr];
            cpu.pc +%= 3;
        },
        0x3b => {
            //DCX SP (SP = SP - 1)
            cpu.sp -%= 1;
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x3e => {
            //MVI A, D8 (A = D8)
            cpu.a = op[1];
            cpu.pc +%= 2;
        },
        0x3f => {
            cpu.cc.cy = ~cpu.cc.cy;
        },
        0x40 => {
            //MOV B, B (B = B)
            cpu.b = cpu.b;
            cpu.pc +%= 1;
        },
        0x41 => {
            //MOV B, C (B = C)
            cpu.b = cpu.c;
            cpu.pc +%= 1;
        },
        0x42 => {
            //MOV B, D (B = D)
            cpu.b = cpu.d;
            cpu.pc +%= 1;
        },
        0x43 => {
            //MOV B, E (B = E)
            cpu.b = cpu.e;
            cpu.pc +%= 1;
        },
        0x44 => {
            //MOV B, H (B = H)
            cpu.b = cpu.h;
            cpu.pc +%= 1;
        },
        0x45 => {
            //MOV B, L (B = L)
            cpu.b = cpu.l;
            cpu.pc +%= 1;
        },
        0x46 => {
            //MOV B, M (B = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.b = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x47 => {
            //MOV B, A (B = A)
            cpu.b = cpu.a;
            cpu.pc +%= 1;
        },
        0x48 => {
            //MOV C, B (C = B)
            cpu.c = cpu.b;
            cpu.pc +%= 1;
        },
        0x49 => {
            //MOV C, C (C = C)
            cpu.c = cpu.c;
            cpu.pc +%= 1;
        },
        0x4a => {
            //MOV C, D (C = D)
            cpu.c = cpu.d;
            cpu.pc +%= 1;
        },
        0x4b => {
            //MOV C, E (C = E)
            cpu.c = cpu.e;
            cpu.pc +%= 1;
        },
        0x4c => {
            //MOV C, H (C = H)
            cpu.c = cpu.h;
            cpu.pc +%= 1;
        },
        0x4d => {
            //MOV C, L (C = L)
            cpu.c = cpu.l;
            cpu.pc +%= 1;
        },
        0x4e => {
            //MOV C, M (C = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.c = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x4f => {
            //MOV C, A (C = A)
            cpu.c = cpu.a;
            cpu.pc +%= 1;
        },
        0x50 => {
            //MOV D, B (D = B)
            cpu.d = cpu.b;
            cpu.pc +%= 1;
        },
        0x51 => {
            //MOV D, C (D = C)
            cpu.d = cpu.c;
            cpu.pc +%= 1;
        },
        0x52 => {
            //MOV D, D (D = D)
            cpu.d = cpu.d;
            cpu.pc +%= 1;
        },
        0x53 => {
            //MOV D, E (D = E)
            cpu.d = cpu.e;
            cpu.pc +%= 1;
        },
        0x54 => {
            //MOV D, H (D = H)
            cpu.d = cpu.h;
            cpu.pc +%= 1;
        },
        0x55 => {
            //MOV D, L (D = L)
            cpu.d = cpu.l;
            cpu.pc +%= 1;
        },
        0x56 => {
            //MOV D, M (D = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.d = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x57 => {
            //MOV D, A (D = A)
            cpu.d = cpu.a;
            cpu.pc +%= 1;
        },
        0x58 => {
            //MOV E, B (E = B)
            cpu.e = cpu.b;
            cpu.pc +%= 1;
        },
        0x59 => {
            //MOV E, C (E = C)
            cpu.e = cpu.c;
            cpu.pc +%= 1;
        },
        0x5a => {
            //MOV E, D (E = D)
            cpu.e = cpu.d;
            cpu.pc +%= 1;
        },
        0x5b => {
            //MOV E, E (E = E)
            cpu.e = cpu.e;
            cpu.pc +%= 1;
        },
        0x5c => {
            //MOV E, H (E = H)
            cpu.e = cpu.h;
            cpu.pc +%= 1;
        },
        0x5d => {
            //MOV E, L (E = L)
            cpu.e = cpu.l;
            cpu.pc +%= 1;
        },
        0x5e => {
            //MOV E, M (E = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.e = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x5f => {
            //MOV E, A (E = A)
            cpu.e = cpu.a;
            cpu.pc +%= 1;
        },
        0x60 => {
            //MOV H, B (H = B)
            cpu.h = cpu.b;
            cpu.pc +%= 1;
        },
        0x61 => {
            //MOV H, C (H = C)
            cpu.h = cpu.c;
            cpu.pc +%= 1;
        },
        0x62 => {
            //MOV H, D (H = D)
            cpu.h = cpu.d;
            cpu.pc +%= 1;
        },
        0x63 => {
            //MOV H, E (H = E)
            cpu.h = cpu.e;
            cpu.pc +%= 1;
        },
        0x64 => {
            //MOV H, H (H = H)
            cpu.h = cpu.h;
            cpu.pc +%= 1;
        },
        0x65 => {
            //MOV H, L (H = L)
            cpu.h = cpu.l;
            cpu.pc +%= 1;
        },
        0x66 => {
            //MOV H, M (H = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.h = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x67 => {
            //MOV H, A (H = A)
            cpu.h = cpu.a;
            cpu.pc +%= 1;
        },
        0x68 => {
            //MOV L, B (L = B)
            cpu.l = cpu.b;
            cpu.pc +%= 1;
        },
        0x69 => {
            //MOV L, C (L = C)
            cpu.l = cpu.c;
            cpu.pc +%= 1;
        },
        0x6a => {
            //MOV L, D (L = D)
            cpu.l = cpu.d;
            cpu.pc +%= 1;
        },
        0x6b => {
            //MOV L, E (L = E)
            cpu.l = cpu.e;
            cpu.pc +%= 1;
        },
        0x6c => {
            //MOV L, H (L = H)
            cpu.l = cpu.h;
            cpu.pc +%= 1;
        },
        0x6d => {
            //MOV L, L (L = L)
            cpu.l = cpu.l;
            cpu.pc +%= 1;
        },
        0x6e => {
            //MOV L, M (L = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.l = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x6f => {
            //MOV L, A (L = A)
            cpu.l = cpu.a;
            cpu.pc +%= 1;
        },
        0x70 => {
            //MOV M, B ((HL) = B)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.b;
            cpu.pc +%= 1;
        },
        0x71 => {
            //MOV M, C ((HL) = C)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.c;
            cpu.pc +%= 1;
        },
        0x72 => {
            //MOV M, D ((HL) = D)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.d;
            cpu.pc +%= 1;
        },
        0x73 => {
            //MOV M, E ((HL) = E)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.e;
            cpu.pc +%= 1;
        },
        0x74 => {
            //MOV M, H ((HL) = H)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.h;
            cpu.pc +%= 1;
        },
        0x75 => {
            //MOV M, L ((HL) = L)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.l;
            cpu.pc +%= 1;
        },
        0x76 => {
            //HLT
            unimplementedOpcode(op[0], cpu);
        },
        0x77 => {
            //MOV M, A ((HL) = A)
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;
            cpu.memory[hl] = cpu.a;
            cpu.pc +%= 1;
        },
        0x78 => {
            //MOV A, B (A = B)
            cpu.a = cpu.b;
            cpu.pc +%= 1;
        },
        0x79 => {
            //MOV A, C (A = C)
            cpu.a = cpu.c;
            cpu.pc +%= 1;
        },
        0x7a => {
            //MOV A, D (A = D)
            cpu.a = cpu.d;
            cpu.pc +%= 1;
        },
        0x7b => {
            //MOV A, E (A = E)
            cpu.a = cpu.e;
            cpu.pc +%= 1;
        },
        0x7c => {
            //MOV A, H (A = H)
            cpu.a = cpu.h;
            cpu.pc +%= 1;
        },
        0x7d => {
            //MOV A, L (A = L)
            cpu.a = cpu.l;
            cpu.pc +%= 1;
        },
        0x7e => {
            //MOV A, M (A = (HL))
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.a = cpu.memory[hl];
            cpu.pc +%= 1;
        },
        0x7f => {
            //MOV A, A (A = A)
            cpu.a = cpu.a;
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x86 => {
            //ADD M (A = A + (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 + op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x8e => {
            //ADC M (A = A + (HL) + CY)
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 + op2 + op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x96 => {
            //SUB M (A = A - (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 - op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0x9e => {
            //SBB M (A = A - (HL) - CY)
            //Dereference loc of HL
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var op3: u16 = cpu.cc.cy;
            var result: u16 = op1 - op2 - op3;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0xa6 => {
            //ANA M (A = A & (HL))
            //Dereference loc of HL
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 & op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0xae => {
            //XRA M (A = A ^ (HL))
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 ^ op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0xb6 => {
            //ORA M (A = A | (HL))
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 | op2;
            cpu.a = @truncate(u8, result);
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(result > 0xff);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0xbe => {
            //CMP M (FLAGS = A - (HL))
            //Dereference loc of HL, add that val
            var op1: u16 = cpu.a;
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            var op2: u16 = cpu.memory[hl];
            var result: u16 = op1 - op2;
            cpu.cc.z = @boolToInt(result == 0);
            cpu.cc.s = @boolToInt(result & 0x80 != 0);
            cpu.cc.cy = @boolToInt(op1 < op2);
            cpu.cc.p = parity(result);
            cpu.pc +%= 1;
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
            cpu.pc +%= 1;
        },
        0xc0 => {
            //RNZ
            if (cpu.cc.z == 0) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xc1 => {
            //POP B (C = (SP), B = (SP +1), SP +%= 2)
            cpu.c = cpu.memory[cpu.sp];
            cpu.b = cpu.memory[cpu.sp + 1];
            cpu.sp +%= 2;
            cpu.pc +%= 1;
        },
        0xc2 => {
            //JNZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.z == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xc3 => {
            //JMP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc = jmp_to;
        },
        0xc4 => {
            //CNZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.z == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
        },
        0xc5 => {
            //PUSH B ((SP-1) = B, (SP-2) = C, SP -%= 2)
            cpu.memory[cpu.sp - 1] = cpu.b;
            cpu.memory[cpu.sp - 2] = cpu.c;
            cpu.sp -%= 2;
            cpu.pc +%= 1;
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
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xc9 => {
            //RET
            var jmp_to: u16 = cpu.memory[cpu.sp + 1];
            jmp_to = jmp_to << 8;
            jmp_to +%= cpu.memory[cpu.sp];

            //Increment SP, jump
            cpu.sp +%= 2;
            cpu.pc = jmp_to;
        },
        0xca => {
            //JZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.z == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xcc => {
            //CZ addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.z == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
        },
        0xcd => {
            //CALL addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            // Check for use of CP/M OS print routine
            if (cpu.cpm_hook and cpu.c == 9 and jmp_to == 5) {
                var de: u16 = cpu.d;
                de = de << 8;
                de +%= cpu.e;
                var i: u16 = de;
                while(cpu.memory[i] != '$' and i < mem_size) {
                    _ = stdout.writer().print("{c}", .{cpu.memory[i]}) catch {};
                    i +%= 1;
                }
                cpu.pc +%= 3;
            }
            else {
                //Write ret addr
                cpu.pc +%= 3;
                cpu.memory[cpu.sp -% 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp -% 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
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
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xd1 => {
            //POP D (E = (SP), D = (SP +1), SP +%= 2)
            cpu.e = cpu.memory[cpu.sp];
            cpu.d = cpu.memory[cpu.sp + 1];
            cpu.sp +%= 2;
            cpu.pc +%= 1;
        },
        0xd2 => {
            //JNC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.cy == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xd3 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xd4 => {
            //CNC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.cy == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
        },
        0xd5 => {
            //PUSH D ((SP-1) = D, (SP-2) = E, SP -%= 2)
            cpu.memory[cpu.sp - 1] = cpu.d;
            cpu.memory[cpu.sp - 2] = cpu.e;
            cpu.sp -%= 2;
            cpu.pc +%= 1;
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
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xda => {
            //JC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.cy == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xdb => {
            unimplementedOpcode(op[0], cpu);
        },
        0xdc => {
            //CC addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.cy == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
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
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xe1 => {
            //POP H (L = (SP), H = (SP +1), SP +%= 2)
            cpu.l = cpu.memory[cpu.sp];
            cpu.h = cpu.memory[cpu.sp + 1];
            cpu.sp +%= 2;
            cpu.pc +%= 1;
        },
        0xe2 => {
            //JPO addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.p == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
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
            cpu.pc +%= 1;
        },
        0xe4 => {
            //CPO addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.p == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
        },
        0xe5 => {
            //PUSH H ((SP-1) = H, (SP-2) = L, SP -%= 2)
            cpu.memory[cpu.sp - 1] = cpu.h;
            cpu.memory[cpu.sp - 2] = cpu.l;
            cpu.sp -%= 2;
            cpu.pc +%= 1;
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
            cpu.pc +%= 2;
        },
        0xe7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xe8 => {
            //RPE
            if (cpu.cc.p == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xe9 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xea => {
            //JPE addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.p == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xeb => {
            //XCHG (DE <-> HL)
            var de: u16 = cpu.d;
            de = de << 8;
            de +%= cpu.e;
            
            var hl: u16 = cpu.h;
            hl = hl << 8;
            hl +%= cpu.l;

            cpu.d = @truncate(u8, hl >> 8);
            cpu.e = @truncate(u8, hl);

            cpu.h = @truncate(u8, de >> 8);
            cpu.l = @truncate(u8, de);

            cpu.pc +%= 1;
        },
        0xec => {
            //CPE addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.p == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
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
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xf1 => {
            //POP PSW (FLAGS = (SP), A = (SP +1), SP +%= 2)
            var flags: u8 = cpu.memory[cpu.sp];
            cpu.cc.z = @boolToInt((flags & 1) == 1);
            cpu.cc.s = @boolToInt((flags & 2) == 2);
            cpu.cc.p = @boolToInt((flags & 4) == 4);
            cpu.cc.cy = @boolToInt((flags & 8) == 8);
            cpu.cc.ac = @boolToInt((flags & 16) == 16);

            cpu.a = cpu.memory[cpu.sp + 1];
            cpu.sp +%= 2;
            cpu.pc +%= 1;
        },
        0xf2 => {
            //JP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.s == 0) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xf3 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xf4 => {
            //CP addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.s == 0) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
                cpu.pc = jmp_to;
            }
        },
        0xf5 => {
            //PUSH PSW ((SP-2) = FLAGS, (SP-1) = A, SP -%= 2)
            var flags: u8 = 0;
            flags = (flags | cpu.cc.ac) << 4;
            flags = (flags | cpu.cc.cy) << 3;
            flags = (flags | cpu.cc.p) << 2;
            flags = (flags | cpu.cc.s) << 1;
            flags = flags | cpu.cc.z;

            cpu.memory[cpu.sp - 2] = flags;
            cpu.memory[cpu.sp - 1] = cpu.a;
            cpu.sp -%= 2;
            cpu.pc +%= 1;
        },
        0xf6 => {
            //ORI D8 (A = A | D8)
            cpu.a = cpu.a | op[1];
            cpu.pc +%= 2;
        },
        0xf7 => {
            unimplementedOpcode(op[0], cpu);
        },
        0xf8 => {
            //RM
            if (cpu.cc.s == 1) {
                var jmp_to: u16 = cpu.memory[cpu.sp + 1];
                jmp_to = jmp_to << 8;
                jmp_to +%= cpu.memory[cpu.sp];

                //Increment SP, jump
                cpu.sp +%= 2;
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 1;
            }
        },
        0xf9 => {
            //SPHL (SP = HL)
            var new_sp: u16 = cpu.h;
            new_sp = new_sp << 8;
            new_sp +%= cpu.l;
            cpu.sp = new_sp;
            cpu.pc +%= 1;
        },
        0xfa => {
            //JM addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];

            if (cpu.cc.s == 1) {
                cpu.pc = jmp_to;
            } else {
                cpu.pc +%= 3;
            }
        },
        0xfb => {
            unimplementedOpcode(op[0], cpu);
        },
        0xfc => {
            //CM addr
            var jmp_to: u16 = op[2];
            jmp_to = jmp_to << 8;
            jmp_to +%= op[1];
            cpu.pc +%= 3;
            if (cpu.cc.s == 1) {
                //Write ret addr
                cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
                cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
                //Decrement SP, jump
                cpu.sp -%= 2;
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
            cpu.pc +%= 1;
        },
        0xff => {
            //RST 7 (CALL 0x38)
            var jmp_to: u16 = 0x38;
            cpu.pc +%= 1;
            cpu.memory[cpu.sp - 2] = @truncate(u8, cpu.pc);
            cpu.memory[cpu.sp - 1] = @truncate(u8, (cpu.pc >> 8));
            //Decrement SP, jump
            cpu.sp -%= 2;
            cpu.pc = jmp_to;
        },
        //NOPS
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x18 => {
            cpu.pc +%= 1;
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
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     NOP", .{op});
            return 1;
        },
        0x01 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LXI B, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x02 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     STAX B", .{op});
            return 1;
        },
        0x03 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INX B", .{op});
            return 1;
        },
        0x04 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR B", .{op});
            return 1;
        },
        0x05 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR B", .{op});
            return 1;
        },
        0x06 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI B, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x07 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RLC", .{op});
            return 1;
        },
        0x09 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DAD B", .{op});
            return 1;
        },
        0x0a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     LDAX B", .{op});
            return 1;
        },
        0x0b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCX B", .{op});
            return 1;
        },
        0x0c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR C", .{op});
            return 1;
        },
        0x0d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR C", .{op});
            return 1;
        },
        0x0e => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI C, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x0f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RRC", .{op});
            return 1;
        },
        0x11 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LXI D, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x12 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     STAX D", .{op});
            return 1;
        },
        0x13 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INX D", .{op});
            return 1;
        },
        0x14 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR D", .{op});
            return 1;
        },
        0x15 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR D", .{op});
            return 1;
        },
        0x16 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI D,  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x17 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RAL", .{op});
            return 1;
        },
        0x19 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DAD D", .{op});
            return 1;
        },
        0x1a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     LDAX D", .{op});
            return 1;
        },
        0x1b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCX D", .{op});
            return 1;
        },
        0x1c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR E", .{op});
            return 1;
        },
        0x1d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR E", .{op});
            return 1;
        },
        0x1e => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI E, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x1f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RAR", .{op});
            return 1;
        },
        0x20 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RIM", .{op});
            return 1;
        },
        0x21 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LXI H, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x22 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " SHLD 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x23 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INX H", .{op});
            return 1;
        },
        0x24 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR H", .{op});
            return 1;
        },
        0x25 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR H", .{op});
            return 1;
        },
        0x26 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI H, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x27 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DAA", .{op});
            return 1;
        },
        0x29 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DAD H", .{op});
            return 1;
        },
        0x2a => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LHLD 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x2b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCX H", .{op});
            return 1;
        },
        0x2c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR L", .{op});
            return 1;
        },
        0x2d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR L", .{op});
            return 1;
        },
        0x2e => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI L,  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x2f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMA", .{op});
            return 1;
        },
        0x31 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LXI SP, 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x32 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " STA 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x33 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INX SP", .{op});
            return 1;
        },
        0x34 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR M", .{op});
            return 1;
        },
        0x35 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR M", .{op});
            return 1;
        },
        0x36 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI M, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x37 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     STC", .{op});
            return 1;
        },
        0x39 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DAD SP", .{op});
            return 1;
        },
        0x3a => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " LDA 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0x3b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCX SP", .{op});
            return 1;
        },
        0x3c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     INR A", .{op});
            return 1;
        },
        0x3d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DCR A", .{op});
            return 1;
        },
        0x3e => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   MVI A, 0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0x3f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMC", .{op});
            return 1;
        },
        0x40 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,B", .{op});
            return 1;
        },
        0x41 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,C", .{op});
            return 1;
        },
        0x42 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,D", .{op});
            return 1;
        },
        0x43 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,E", .{op});
            return 1;
        },
        0x44 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,H", .{op});
            return 1;
        },
        0x45 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,L", .{op});
            return 1;
        },
        0x46 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,M", .{op});
            return 1;
        },
        0x47 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV B,A", .{op});
            return 1;
        },
        0x48 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,B", .{op});
            return 1;
        },
        0x49 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,C", .{op});
            return 1;
        },
        0x4a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,D", .{op});
            return 1;
        },
        0x4b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,E", .{op});
            return 1;
        },
        0x4c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,H", .{op});
            return 1;
        },
        0x4d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,L", .{op});
            return 1;
        },
        0x4e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,M", .{op});
            return 1;
        },
        0x4f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV C,A", .{op});
            return 1;
        },
        0x50 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,B", .{op});
            return 1;
        },
        0x51 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,C", .{op});
            return 1;
        },
        0x52 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,D", .{op});
            return 1;
        },
        0x53 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,E", .{op});
            return 1;
        },
        0x54 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,H", .{op});
            return 1;
        },
        0x55 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,L", .{op});
            return 1;
        },
        0x56 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,M", .{op});
            return 1;
        },
        0x57 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV D,A", .{op});
            return 1;
        },
        0x58 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,B", .{op});
            return 1;
        },
        0x59 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,C", .{op});
            return 1;
        },
        0x5a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,D", .{op});
            return 1;
        },
        0x5b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,E", .{op});
            return 1;
        },
        0x5c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,H", .{op});
            return 1;
        },
        0x5d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,L", .{op});
            return 1;
        },
        0x5e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,M", .{op});
            return 1;
        },
        0x5f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV E,A", .{op});
            return 1;
        },
        0x60 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,B", .{op});
            return 1;
        },
        0x61 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,C", .{op});
            return 1;
        },
        0x62 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,D", .{op});
            return 1;
        },
        0x63 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,E", .{op});
            return 1;
        },
        0x64 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,H", .{op});
            return 1;
        },
        0x65 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,L", .{op});
            return 1;
        },
        0x66 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,M", .{op});
            return 1;
        },
        0x67 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV H,A", .{op});
            return 1;
        },
        0x68 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,B", .{op});
            return 1;
        },
        0x69 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,C", .{op});
            return 1;
        },
        0x6a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,D", .{op});
            return 1;
        },
        0x6b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,E", .{op});
            return 1;
        },
        0x6c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,H", .{op});
            return 1;
        },
        0x6d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,L", .{op});
            return 1;
        },
        0x6e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,M", .{op});
            return 1;
        },
        0x6f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV L,A", .{op});
            return 1;
        },
        0x70 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,B", .{op});
            return 1;
        },
        0x71 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,C", .{op});
            return 1;
        },
        0x72 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,D", .{op});
            return 1;
        },
        0x73 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,E", .{op});
            return 1;
        },
        0x74 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,H", .{op});
            return 1;
        },
        0x75 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,L", .{op});
            return 1;
        },
        0x76 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     HLT", .{op});
            return 1;
        },
        0x77 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV M,A", .{op});
            return 1;
        },
        0x78 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,B", .{op});
            return 1;
        },
        0x79 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,C", .{op});
            return 1;
        },
        0x7a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,D", .{op});
            return 1;
        },
        0x7b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,E", .{op});
            return 1;
        },
        0x7c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,H", .{op});
            return 1;
        },
        0x7d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,L", .{op});
            return 1;
        },
        0x7e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,M", .{op});
            return 1;
        },
        0x7f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     MOV A,A", .{op});
            return 1;
        },
        0x80 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD B", .{op});
            return 1;
        },
        0x81 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD C", .{op});
            return 1;
        },
        0x82 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD D", .{op});
            return 1;
        },
        0x83 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD E", .{op});
            return 1;
        },
        0x84 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD H", .{op});
            return 1;
        },
        0x85 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD L", .{op});
            return 1;
        },
        0x86 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD M", .{op});
            return 1;
        },
        0x87 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADD A", .{op});
            return 1;
        },
        0x88 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC B", .{op});
            return 1;
        },
        0x89 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC C", .{op});
            return 1;
        },
        0x8a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC D", .{op});
            return 1;
        },
        0x8b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC E", .{op});
            return 1;
        },
        0x8c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC H", .{op});
            return 1;
        },
        0x8d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC L", .{op});
            return 1;
        },
        0x8e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC M", .{op});
            return 1;
        },
        0x8f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ADC A", .{op});
            return 1;
        },
        0x90 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB B", .{op});
            return 1;
        },
        0x91 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB C", .{op});
            return 1;
        },
        0x92 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB D", .{op});
            return 1;
        },
        0x93 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB E", .{op});
            return 1;
        },
        0x94 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB H", .{op});
            return 1;
        },
        0x95 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB L", .{op});
            return 1;
        },
        0x96 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB M", .{op});
            return 1;
        },
        0x97 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SUB A", .{op});
            return 1;
        },
        0x98 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB B", .{op});
            return 1;
        },
        0x99 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB C", .{op});
            return 1;
        },
        0x9a => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB D", .{op});
            return 1;
        },
        0x9b => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB E", .{op});
            return 1;
        },
        0x9c => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB H", .{op});
            return 1;
        },
        0x9d => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB L", .{op});
            return 1;
        },
        0x9e => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB M", .{op});
            return 1;
        },
        0x9f => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SBB A", .{op});
            return 1;
        },
        0xa0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA B", .{op});
            return 1;
        },
        0xa1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA C", .{op});
            return 1;
        },
        0xa2 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA D", .{op});
            return 1;
        },
        0xa3 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA E", .{op});
            return 1;
        },
        0xa4 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA H", .{op});
            return 1;
        },
        0xa5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA L", .{op});
            return 1;
        },
        0xa6 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA M", .{op});
            return 1;
        },
        0xa7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ANA A", .{op});
            return 1;
        },
        0xa8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA B", .{op});
            return 1;
        },
        0xa9 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA C", .{op});
            return 1;
        },
        0xaa => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA D", .{op});
            return 1;
        },
        0xab => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA E", .{op});
            return 1;
        },
        0xac => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA H", .{op});
            return 1;
        },
        0xad => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA L", .{op});
            return 1;
        },
        0xae => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA M", .{op});
            return 1;
        },
        0xaf => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XRA A", .{op});
            return 1;
        },
        0xb0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA B", .{op});
            return 1;
        },
        0xb1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA C", .{op});
            return 1;
        },
        0xb2 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA D", .{op});
            return 1;
        },
        0xb3 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA E", .{op});
            return 1;
        },
        0xb4 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA H", .{op});
            return 1;
        },
        0xb5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA L", .{op});
            return 1;
        },
        0xb6 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA M", .{op});
            return 1;
        },
        0xb7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     ORA A", .{op});
            return 1;
        },
        0xb8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP B", .{op});
            return 1;
        },
        0xb9 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP C", .{op});
            return 1;
        },
        0xba => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP D", .{op});
            return 1;
        },
        0xbb => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP E", .{op});
            return 1;
        },
        0xbc => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP H", .{op});
            return 1;
        },
        0xbd => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP L", .{op});
            return 1;
        },
        0xbe => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP M", .{op});
            return 1;
        },
        0xbf => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     CMP A", .{op});
            return 1;
        },
        0xc0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RNZ", .{op});
            return 1;
        },
        0xc1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     POP B", .{op});
            return 1;
        },
        0xc2 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JNZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc3 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JMP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc4 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CNZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xc5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     PUSH B", .{op});
            return 1;
        },
        0xc6 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   ADI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xc7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 0", .{op});
            return 1;
        },
        0xc8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RZ", .{op});
            return 1;
        },
        0xc9 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RET", .{op});
            return 1;
        },
        0xca => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcc => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CZ 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xcd => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CALL 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xce => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   ACI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xcf => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 1", .{op});
            return 1;
        },
        0xd0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RNC", .{op});
            return 1;
        },
        0xd1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     POP D", .{op});
            return 1;
        },
        0xd2 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JNC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd3 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   OUT  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xd4 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CNC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xd5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     PUSH D", .{op});
            return 1;
        },
        0xd6 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   SUI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xd7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 2", .{op});
            return 1;
        },
        0xd8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RC", .{op});
            return 1;
        },
        0xda => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xdb => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   IN  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xdc => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CC 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xde => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   SBI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xdf => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 3", .{op});
            return 1;
        },
        0xe0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RPO", .{op});
            return 1;
        },
        0xe1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     POP H", .{op});
            return 1;
        },
        0xe2 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JPO 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe3 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XTHL", .{op});
            return 1;
        },
        0xe4 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CPO 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xe5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     PUSH H", .{op});
            return 1;
        },
        0xe6 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   ANI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xe7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 4", .{op});
            return 1;
        },
        0xe8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RPE", .{op});
            return 1;
        },
        0xe9 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     PCHL", .{op});
            return 1;
        },
        0xea => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JPE 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xeb => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     XCHG", .{op});
            return 1;
        },
        0xec => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CPE 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xee => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   XRI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xef => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 5", .{op});
            return 1;
        },
        0xf0 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RP", .{op});
            return 1;
        },
        0xf1 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     POP PSW", .{op});
            return 1;
        },
        0xf2 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf3 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     DI", .{op});
            return 1;
        },
        0xf4 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CP 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xf5 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     PUSH PSW", .{op});
            return 1;
        },
        0xf6 => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   ORI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xf7 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 6", .{op});
            return 1;
        },
        0xf8 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RM", .{op});
            return 1;
        },
        0xf9 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     SPHL", .{op});
            return 1;
        },
        0xfa => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " JM 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfb => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     EI", .{op});
            return 1;
        },
        0xfc => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ " CM 0x{x:0>2}{x:0>2}", .{ op, b1, b2, b2, b1 });
            return 3;
        },
        0xfe => {
            print(colors.BLUE ++ "{x:0>2}{x:0>2}" ++ colors.DEFAULT ++ "   CPI  0x{x:0>2}", .{ op, b1, b1 });
            return 2;
        },
        0xff => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     RST 7", .{op});
            return 1;
        },
        0xfd, 0xed, 0x08, 0x10, 0xdd, 0xd9, 0xcb, 0x38, 0x30, 0x28, 0x18 => {
            print(colors.BLUE ++ "{x:0>2}" ++ colors.DEFAULT ++ "     NOP", .{op});
            return 1;
        },
    }
    return 0;
}


//TODO - overhaul memdumpCmd and hexdump to account for length
//and to print addresses next to dump
//...perhaps a byte & word option would be nice too
//Would be easy to write a hexdumpWord func and swap between the
//two in memdumpCmd

pub fn memdumpCmd(pCpu: *CPU, args: [][]const u8) void {
    var addr: u16 = undefined;
    var len: u16 = 48;
    if (args.len == 2) {
        addr = std.fmt.parseInt(u16, args[1], 0) catch blk: {
            _ = stdout.writer().print(colors.RED ++ "Invalid address: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
            break :blk 0;
        };
    } 
    else if (args.len >= 3) {
        addr = std.fmt.parseInt(u16, args[1], 0) catch blk: {
            _ = stdout.writer().print(colors.RED ++ "Invalid address: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[1]}) catch {};
            break :blk 0;
        };
        len = std.fmt.parseInt(u16, args[2], 0) catch blk: {
            _ = stdout.writer().print(colors.RED ++ "Invalid length: '{s}'" ++ colors.DEFAULT ++ "\n", .{args[2]}) catch {};
            break :blk 0;
        };
    }
    else {
        _ = stdout.writer().print(colors.RED ++ "Address required" ++ colors.DEFAULT ++ "\n", .{}) catch {};
        return;
    }
    //needed this for to avoid integer overflow...
    var len_as_u17: u17 = @as(u17, len);
    var addr_as_u17: u17 = @as(u17, addr);
    const checkLen: u17 = len_as_u17 + addr_as_u17;
    if (checkLen >= pCpu.memory.len){
        _ = stdout.writer().print(colors.RED ++ "Length: '{d}' exceeds memory boundary" ++ colors.DEFAULT ++ "\n", .{len}) catch {};
        return;
    }
    hexdump(pCpu.memory, addr, len);
}

fn isPrintable(char: u8) u8 {
    if (char < 0x20 or char > 0x7e) {
        return '.';
    }
    return char;
}

pub fn hexdump(buf: []u8, pc: u16, amount: u16) void {
    const num_rows: u16 = amount / 8;
    var locPc: u16 = pc;
    var writer = stdout.writer();
    var i: u16 = 0;
    var fillspace = 8 - (amount % 8); 

    while(amount >= 8 and i < num_rows) {
        _ = writer.print("0x{x:0>4} | ", .{locPc}) catch {};
        for(buf[locPc .. locPc+8]) |val| {
            _ = writer.print("{x:0>2} ", .{val}) catch {};
        }
        _ = writer.write("| ") catch {};
        for(buf[locPc .. locPc+8]) |val| {
            _ = writer.print("{c} ", .{isPrintable(val)}) catch {};
        }
        _ = writer.write("|\n") catch {};
        i += 1;
        locPc += 8;
    }
    if (fillspace == 8)
        fillspace = 0;
    if (fillspace > 0){
        _ = writer.print("0x{x:0>4} | ", .{locPc}) catch {};
        for(buf[locPc .. locPc+amount-(locPc-pc)]) |val| {
            _ = writer.print("{x:0>2} ", .{val}) catch {};
        }
        if (fillspace > 0){
            i = 0;
            while(i < fillspace){
                _ = writer.write("   ") catch {};
                i += 1;
            }
        }
        _ = writer.write("| ") catch {};
        for(buf[locPc .. locPc+amount-(locPc-pc)]) |val| {
            _ = writer.print("{c} ", .{isPrintable(val)}) catch {};
        }
        if (fillspace > 0){
            i = 0;
            while(i < fillspace){
                _ = writer.write("  ") catch {};
                i += 1;
            }
        }
        _ = writer.write("|\n") catch {};
    }
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
    cflags.z = 0;
    cflags.s = 0;
    cflags.p = 0;
    cflags.cy = 0;
    cflags.ac = 0;
    cflags.pad = 0;

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

    cpu.cpm_hook = false;
    cpu.status_print = false;

    return cpu;
}
