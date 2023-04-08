const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

///TODO
pub fn createCommand(comptime T: type) type {
    return struct {
        key: []const u8,
        func: *T,
    };
}

///TODO - take in comptime command structs and
///map them to a hashmap
pub fn initCmdHashMap() void {}

///Provide user input prompt.
///Array of user inputs are returned
pub fn prompt(alloc: std.mem.Allocator) ![][]const u8 {
    _ = try stdout.writer().write("> ");
    var buf = try stdin.reader().readUntilDelimiterAlloc(alloc, '\n', std.math.maxInt(u32));
    var cmdIterator = std.mem.split(u8, buf, " ");

    var cmdList = std.ArrayList([]const u8).init(alloc);

    const largeCmd = cmdIterator.first();
    try cmdList.append(largeCmd);
    while (cmdIterator.next()) |arg| {
        try cmdList.append(arg);
    }
    return cmdList.toOwnedSlice();
}
