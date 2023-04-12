const std = @import("std");
const icpu = @import("cpu");
const icli = @import("cli");
const stdout = std.io.getStdOut();

fn initCallbacks() icli.CmdStruct {
    const print_cpu_callback = icli.Callback{ .with_cpu = &icpu.printCpuCmd };
    const print_cpu_cmd = icli.CmdStruct{ .key = "r", .help_msg = "halp!\n", .callback = print_cpu_callback };
    return print_cpu_cmd;
}

var stop: bool = false;

fn parseCommands(args: [][]const u8, pCpu: *icpu.CPU) !void {
    if (std.mem.eql(u8, args[0], "q")) {
        stop = true;
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

    var dummy_args1: [2][]const u8 = [_][]const u8{ "ab", "c" };
    var dummy_args2: [][]const u8 = &dummy_args1;

    var safe = [_][]const u8{"r"};
    var prevResponse: [][]const u8 = &safe;
    const callMe = initCallbacks();
    switch (callMe.callback) {
        .with_cpu => {
            callMe.callback.with_cpu(cpu, dummy_args2);
        },
        .without_cpu => {},
    }

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
