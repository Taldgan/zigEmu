const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const CPU = @import("cpu.zig").CPU;

var cmd_map: std.StringHashMap(CmdStruct) = undefined;

pub fn initHashMap(alloc: std.mem.Allocator, cmd_listp: *[]CmdStruct) !void {
    var cmd_hash_map: std.StringHashMap(CmdStruct) = std.StringHashMap(CmdStruct).init(alloc);
    var cmd_list: []CmdStruct = cmd_listp.*;

    for (cmd_list) |cmd| {
        try cmd_hash_map.put(cmd.key, cmd);
    }
    cmd_map = cmd_hash_map;
}

pub const Callback = union(enum) {
    with_cpu: *const fn (*CPU, [][]const u8) void,
    without_cpu: *const fn ([][]const u8) void,
};

pub const CmdStruct = struct {
    key: []const u8,
    help_msg: []const u8,
    callback: Callback,
};

pub fn parseCommands(args: [][]const u8, pCpu: *CPU) !void {
    if (cmd_map.get(args[0])) |cmd| {
        switch (cmd.callback) {
            .with_cpu => {
                cmd.callback.with_cpu(pCpu, args);
            },
            .without_cpu => {
                cmd.callback.without_cpu(args);
            },
        }
    } else {
        try stdout.writer().print("Invalid command '{s}'\n", .{args[0]});
    }
}

///Iterate through global CmdStringHashMap, printing help options
///Alternatively if args contain a command or list of commands, print
///the relevant help options.
pub fn helpCmd(args: [][]const u8) void {
    if (args.len == 1) {
        var mapIterator = cmd_map.valueIterator();
        while (mapIterator.next()) |cmd| {
            _ = stdout.writer().print("{s}", .{cmd.help_msg}) catch {};
        }
    } else {
        for (args[1..]) |cmd| {
            var opt = cmd_map.get(cmd);
            if (opt) |cmd_exists| {
                _ = stdout.writer().print("{s}", .{cmd_exists.help_msg}) catch {};
            }
        }
    }
}

///Provide user input prompt.
///Array of user inputs are returned
pub fn prompt(alloc: std.mem.Allocator) ![][]const u8 {
    _ = try stdout.writer().write("> ");
    var buf = try stdin.reader().readUntilDelimiterAlloc(alloc, '\n', std.math.maxInt(u32));
    var cmdIterator = std.mem.tokenize(u8, buf, " ");

    var cmdList = std.ArrayList([]const u8).init(alloc);

    while (cmdIterator.next()) |arg| {
        try cmdList.append(arg);
    }
    if (cmdList.items.len == 0) {
        try cmdList.append("");
    }
    return cmdList.toOwnedSlice();
}
