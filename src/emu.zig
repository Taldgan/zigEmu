const std = @import("std");
const icpu = @import("cpu");
const icli = @import("cli");
const stdout = std.io.getStdOut();

fn initCallbacks(alloc: std.mem.Allocator) ![]icli.CmdStruct {
    var cmd_list = std.ArrayList(icli.CmdStruct).init(alloc);
    var key_list = std.ArrayList([]const u8).init(alloc);

    try key_list.append("r");
    try key_list.append("cpu");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(), 
        .help_msg = icli.HelpMsg {
            .cmd = "cpu",
            .args = "[reg/flags]",
            .desc = "print registers of cpu",
        },
        .callback = icli.Callback{ .with_cpu = &icpu.printCpuCmd } });

    try key_list.append("x");
    try key_list.append("hexdump");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "hexdump",
            .args = "[addr]",
            .desc = "hexdump of address",
        },
        .callback = icli.Callback{ .with_cpu = &icpu.memdumpCmd } });

    try key_list.append("s");
    try key_list.append("step");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "step",
            .args = "[x]",
            .desc = "emulate and step 'x' instructions",
        },
        .callback =  icli.Callback { .with_cpu = &icpu.stepCmd} });

    try key_list.append("d");
    try key_list.append("disas");
    try key_list.append("disassemble");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "disassemble",
            .args = "[pc/addr] [x]",
            .desc = "disassemble 8 (or 'x') instructions at address or pc",
        },
        .callback =  icli.Callback{ .with_cpu = &icpu.disassembleCmd  } });

    try key_list.append("l");
    try key_list.append("load");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "load",
            .args = "[addr]",
            .desc = "maps file into memory at emulated cpu address 'addr'",
        },
        .callback =  icli.Callback{ .with_cpu = &icpu.loadCmd } });

    try key_list.append("q");
    try key_list.append("quit");
    try key_list.append("exit");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "quit",
            .args = "",
            .desc = "quit the emulator",
        },
        .callback = icli.Callback {  .without_cpu = &quit  } });

    try key_list.append("c");
    try key_list.append("continue");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "continue",
            .args = "[addr]",
            .desc = "continue, or continue until given address",
        },
        .callback = icli.Callback { .with_cpu = &icpu.continueCmd } });

    try key_list.append("b");
    try key_list.append("break");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "break",
            .args = "[e id/d id/c id/addr]",
            .desc = "List breakpoints, set a breakpoint on addr, or enable/disable/clear breakpoints by id",
        },
        .callback = icli.Callback { .with_cpu = &icpu.breakCmd } });

    try key_list.append("h");
    try key_list.append("?");
    try key_list.append("help");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "help",
            .args = "[cmd1 cmd2 cmd3...]",
            .desc = "print this menu, or help of a specific command",
        },
        .callback = icli.Callback { .without_cpu = &icli.helpCmd } });

    try key_list.append("cpm");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "cpm",
            .args = "",
            .desc = "toggle CP/M OS Hook for print routine",
        },
        .callback = icli.Callback { .with_cpu = &icpu.cpmHookCmd } });

    try key_list.append("status");
    try cmd_list.append(icli.CmdStruct{ 
        .keys = key_list.toOwnedSlice(),
        .help_msg = icli.HelpMsg {
            .cmd = "status",
            .args = "",
            .desc = "toggle print cpu status after step",
        },
        .callback = icli.Callback { .with_cpu = &icpu.statusPrintCmd } });

    return cmd_list.toOwnedSlice();
}

var stop: bool = false;

fn quit(args: [][]const u8) void {
    stop = true;
    _ = args;
}

pub fn main() !void {
    //Arena Allocator init & defer denit
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    //Necessary to identify arrow inputs
    icli.disableLineBuffering();

    var buf: [icpu.mem_size]u8 = undefined;
    for (buf) |_, i| {
        buf[i] = 0;
    }
    var cpu = try icpu.initCpu(&buf, alloc);

    var safe = [_][]const u8{"r"};
    var prevResponse: [][]const u8 = &safe;

    //Initilialize callbacks, then create cli global hashmap containing commands
    var cmd_list = try initCallbacks(alloc);
    icli.setGlobAlloc(alloc);
    icpu.setGlobAlloc(alloc);
    try icli.initHashMap(alloc, &cmd_list);
    try icli.loadCmdHistory();

    while (true) {
        var response: [][]const u8 = try icli.promptWithArrows(alloc);
        //Repeat prev command if only 'enter' is pressed...
        if (std.mem.eql(u8, response[0], "")) {
            try icli.parseCommands(prevResponse, cpu, true);
        } else {
            prevResponse = response;
            try icli.parseCommands(response, cpu, false);
        }
        if (stop) {
            break;
        }
    }
    _ = try icli.writeCommandHistory();
}
