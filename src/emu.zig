const std = @import("std");
const icpu = @import("cpu");
const icli = @import("cli");
const stdout = std.io.getStdOut();

fn initCallbacks(alloc: std.mem.Allocator) ![]icli.CmdStruct {
    var cmd_list = std.ArrayList(icli.CmdStruct).init(alloc);

    try cmd_list.append(icli.CmdStruct{ 
        .key = "r", 
        .help_msg = "\x1b[34mr [reg/flags] \x1b[0m - print status/registers of cpu\n", 
        .callback = icli.Callback{ .with_cpu = &icpu.printCpuCmd } });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "d", 
        .help_msg = "\x1b[34md [addr] \x1b[0m - hexdump of address\n", 
        .callback = icli.Callback{ .with_cpu = &icpu.memdumpCmd } });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "s", 
        .help_msg = "\x1b[34ms [x] \x1b[0m- emulate and step 'x' instructions\n", 
        .callback =  icli.Callback { .with_cpu = &icpu.stepCmd} });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "u", 
        .help_msg = "\x1b[0;34mu [pc/addr] [numInst] \x1b[0m- disassemble 8 instructions at address or pc\n", 
        .callback =  icli.Callback{ .with_cpu = &icpu.disassembleCmd  } });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "load", 
        .help_msg = "\x1b[34mload FILE [addr] \x1b[0m- maps file into memory at emulated cpu address 'addr'\n", 
        .callback =  icli.Callback{ .with_cpu = &icpu.loadCmd } });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "q", 
        .help_msg = "\x1b[34mq \x1b[0m- quit\n", 
        .callback = icli.Callback {  .without_cpu = &quit  } });

    try cmd_list.append(icli.CmdStruct{ 
        .key = "h", 
        .help_msg = "\x1b[34mh [cmd] \x1b[0m- print this menu, or help of a specific command\n", 
        .callback = icli.Callback { .without_cpu = &icli.helpCmd } });

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

    var buf: [icpu.mem_size]u8 = undefined;
    for (buf) |_, i| {
        buf[i] = 0;
    }
    var cpu = try icpu.initCpu(&buf, alloc);

    var safe = [_][]const u8{"r"};
    var prevResponse: [][]const u8 = &safe;

    //Initilialize callbacks, then create cli global hashmap containing commands
    var cmd_list = try initCallbacks(alloc);
    try icli.initHashMap(alloc, &cmd_list);

    while (true) {
        var response: [][]const u8 = try icli.prompt(alloc);
        //Repeat prev command...
        if (std.mem.eql(u8, response[0], "")) {
            try icli.parseCommands(prevResponse, cpu);
        } else {
            prevResponse = response;
            try icli.parseCommands(response, cpu);
        }
        if (stop) {
            break;
        }
    }
}
