const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const CPU = @import("cpu.zig").CPU;

var CmdStringHashMap = undefined;

pub fn initHashMap(cmd_list: []CmdStruct) void {
    _ = cmd_list;
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
