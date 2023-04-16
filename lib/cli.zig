const colors = @import("colors.zig");
const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();
const CPU = @import("cpu.zig").CPU;
const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

var cmd_map: std.StringHashMap(CmdStruct) = undefined;
var cmd_history: []const u8 = undefined;

var globAlloc: std.mem.Allocator = undefined;

pub fn setGlobAlloc(alloc: std.mem.Allocator) void {
    globAlloc = alloc;
}

pub const Callback = union(enum) {
    with_cpu: *const fn (*CPU, [][]const u8) void,
    without_cpu: *const fn ([][]const u8) void,
};

pub const CmdStruct = struct {
    keys: [][]const u8,
    help_msg: HelpMsg,
    callback: Callback,
};

pub const HelpMsg = struct {
    cmd: []const u8,    
    args: []const u8,    
    desc: []const u8,    
};

pub fn initHashMap(alloc: std.mem.Allocator, cmd_listp: *[]CmdStruct) !void {
    var cmd_hash_map: std.StringHashMap(CmdStruct) = std.StringHashMap(CmdStruct).init(alloc);
    var cmd_list: []CmdStruct = cmd_listp.*;

    for (cmd_list) |cmd| {
        for(cmd.keys) |key|{
            try cmd_hash_map.put(key, cmd);
        }
    }
    cmd_map = cmd_hash_map;
}

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

pub fn getUniqueCmds() []CmdStruct {
    var unique_cmds = std.ArrayList(CmdStruct).init(globAlloc);
    var mapIterator = cmd_map.valueIterator();
    var in_unique_cmds: bool = false;
    while(mapIterator.next()) |cmd|{
        in_unique_cmds = false;
        for(unique_cmds.items) |unique_cmd|{
            if(std.mem.eql(u8, cmd.help_msg.cmd, unique_cmd.help_msg.cmd)){
                in_unique_cmds = true;
                break;
            }
        }
        if(!in_unique_cmds){
            _ = unique_cmds.append(cmd.*) catch 0;
            continue;
        }
    }
    return unique_cmds.toOwnedSlice();
}

///Iterate through global CmdStringHashMap, printing help options
///Alternatively if args contain a command or list of commands, print
///the relevant help options.
pub fn helpCmd(args: [][]const u8) void {
    var unique_cmds: []CmdStruct = getUniqueCmds();
    var all_keys = std.ArrayList(u8).init(globAlloc);
    if (args.len == 1) {
        for (unique_cmds) |cmd| {
            for(cmd.keys)|key, i| {
                if(i > 0)
                    _ = all_keys.appendSlice("/") catch 0;
                _ = all_keys.appendSlice(key) catch 0;
            }
            if(cmd.help_msg.args.len != 0){
            _ = stdout.writer().print(colors.BLUE ++ "{s} " ++ colors.YELLOW ++ "{s} " ++ colors.DEFAULT ++ "- {s}\n", 
                .{all_keys.toOwnedSlice(), cmd.help_msg.args, cmd.help_msg.desc}) catch {};
            }
            else{ 
            _ = stdout.writer().print(colors.BLUE ++ "{s} " ++ colors.DEFAULT ++ "- {s}\n", 
                .{all_keys.toOwnedSlice(), cmd.help_msg.desc}) catch {};
            }
        }

    } else {
        for (args[1..]) |cmd| {
            var opt = cmd_map.get(cmd);
            if (opt) |cmd_exists| {
                if(cmd_exists.help_msg.args.len != 0){
                _ = stdout.writer().print(colors.BLUE ++ "{s} " ++ colors.YELLOW ++ "{s} " ++ colors.DEFAULT ++ "- {s}\n", 
                    .{cmd_exists.help_msg.cmd, cmd_exists.help_msg.args, cmd_exists.help_msg.desc}) catch {};
                }
                else{ 
                _ = stdout.writer().print(colors.BLUE ++ "{s} " ++ colors.DEFAULT ++ "- {s}\n", 
                    .{cmd_exists.help_msg.cmd, cmd_exists.help_msg.desc}) catch {};
                }
            }
        }
    }
}

pub fn disableLineBuffering() void {
    const my_termios_type = c.termios;
    var my_termios: my_termios_type = undefined;
    _ = c.tcgetattr(0, &my_termios);
    my_termios.c_lflag &= @as(c_uint, ~@as(c_uint, 2));
    my_termios.c_lflag |= c.ECHO;
    my_termios.c_cc[c.VMIN] = 0;
    my_termios.c_cc[c.VTIME] = 0;
    _ = c.tcsetattr(0, c.TCSANOW, &my_termios);
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
