const std = @import("std");
const icpu = @import("cpu");
const icli = @import("cli");
const stdout = std.io.getStdOut();

var stop: bool = false;

fn parseCommands(args: [][]const u8, pCpu: *icpu.CPU) !void {
    if (std.mem.eql(u8, args[0], "r") or std.mem.eql(u8, args[0], "cpu")) {
        if (args.len == 1) {
            icpu.printCpuStatus(pCpu);
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
                            try stdout.writer().print("\x1b[0;31mInvalid register '{s}'\x1b[0m\n", .{reg});
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
                        try stdout.writer().print("z:{b} s:{b} p:{b} cy:{b} ac:{b}\n", .{ pCpu.cc.z, pCpu.cc.s, pCpu.cc.p, pCpu.cc.cy, pCpu.cc.ac });
                        return;
                    } else {
                        try stdout.writer().print("\x1b[0;31mInvalid register '{s}'\x1b[0m\n", .{reg});
                        return;
                    }
                    break :regVal retMe;
                };
                try stdout.writer().print("{s}: 0x{x:0>2}\n", .{ reg, regBlk });
            }
        }
    } else if (std.mem.eql(u8, args[0], "q")) {
        stop = true;
    } else if (std.mem.eql(u8, args[0], "u") or std.mem.eql(u8, args[0], "d")) {
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
                Static.tmpPc += icpu.disassemble(pCpu.memory, Static.tmpPc);
                _ = try stdout.writer().write("\n");
            }
        } else {
            if (std.mem.eql(u8, args[1], "pc")) {
                Static.tmpPc = pCpu.pc;
                var i: u16 = 0;
                while (i < 8) : (i += 1) {
                    _ = try stdout.writer().print("0x{x:0>2}: ", .{Static.tmpPc});
                    Static.tmpPc += icpu.disassemble(pCpu.memory, Static.tmpPc);
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
                    Static.tmpPc += icpu.disassemble(pCpu.memory, Static.tmpPc);
                    _ = try stdout.writer().write("\n");
                }
            }
        }
    } else if (std.mem.eql(u8, args[0], "s")) {
        if (args.len == 1) {
            icpu.emulate(pCpu);
        } else {
            const steps: u32 = std.fmt.parseInt(u32, args[1], 0) catch blk: {
                try stdout.writer().print("\x1b[0;31mInvalid number of steps: '{s}'\x1b[0m\n", .{args[1]});
                break :blk 0;
            };
            var i: u32 = 0;
            while (i < steps) : (i += 1) {
                icpu.emulate(pCpu);
            }
        }
        _ = try stdout.writer().print("0x{x:0>2}: ", .{pCpu.pc});
        _ = icpu.disassemble(pCpu.memory, pCpu.pc);
        _ = try stdout.writer().write("\n");
    } else if (std.mem.eql(u8, args[0], "load")) {
        if (args.len < 2) {
            return;
        }
        const cwd = std.fs.cwd();
        var file = cwd.openFile(args[1], .{}) catch {
            try stdout.writer().print("\x1b[0;31mUnable to open file '{s}'\x1b[0m\n", .{args[1]});
            return;
        };
        defer file.close();

        _ = try file.readAll(pCpu.memory);
        _ = try stdout.writer().print("\x1b[0;32mMapped file '{s}' into memory at address 0x{x:0>4}\x1b[0m\n", .{ args[1], 0x0 });
    } else if (std.mem.eql(u8, args[0], "help") or std.mem.eql(u8, args[0], "h")) {
        _ = try stdout.writer().print("\x1b[0;34mh \x1b[0m- print this menu\n\x1b[0;34mu [pc/addr] \x1b[0m- disassemble 8 instructions at address or pc\n\x1b[0m\x1b[34ms [x] \x1b[0m- emulate and step 'x' instructions\n\x1b[34mr [reg/flags] \x1b[0m - print status/registers of cpu\n\x1b[34mload FILE [addr] \x1b[0m- maps file into memory at emulated cpu address 'addr'\n", .{});
    } else {
        _ = try stdout.writer().print("\x1b[0;31mUnknown command '{s}'\x1b[0m\n", .{args[0]});
    }
}

pub fn main() !void {
    //Arena Allocator init & defer denit
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    var buf: [0x4000]u8 = undefined;
    for (buf) |_, i| {
        buf[i] = 0;
    }
    var cpu = try icpu.initCpu(&buf, alloc);

    var safe = [_][]const u8{"r"};
    var prevResponse: [][]const u8 = &safe;

    while (true) {
        var response: [][]const u8 = try icli.prompt(alloc);
        //Repeat prev command...
        if (std.mem.eql(u8, response[0], "")) {
            try parseCommands(prevResponse, cpu);
        } else {
            prevResponse = response;
            try parseCommands(response, cpu);
        }
        if (stop) {
            break;
        }
    }
}
