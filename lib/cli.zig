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

const prompt_str: []const u8 = "zig@emu$ ";

var cmd_map: std.StringHashMap(CmdStruct) = undefined;
var cmd_history: std.ArrayList([]const u8) = undefined;
var cmd_index: usize = 0;
var glob_broken: *bool = undefined;

pub var globAlloc: std.mem.Allocator = undefined;

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



fn getCmdFromHistory(up: bool) []const u8 {
    const Static = struct {
        var initialized: bool = false;
    };
    if (!Static.initialized) {
        cmd_index = cmd_history.items.len;
        Static.initialized = true;
    }
    if(cmd_history.items.len == 0){
       return ""; 
    }
    if(up and cmd_index > 0) {
        cmd_index -= 1;
        return cmd_history.items[cmd_index]; 
    }
    else if(!up and cmd_index < cmd_history.items.len - 1){
        cmd_index += 1;
        return cmd_history.items[cmd_index]; 
    }
    else if(cmd_index == 0)
        return cmd_history.items[cmd_index]; 
    return "";
}

pub fn writeCommandHistory() !void {
    const cwd = std.fs.cwd();
    var cmd_history_file = cwd.openFile("history.txt", .{ .mode = std.fs.File.OpenMode.read_write }) catch |err| {
        if(err == std.fs.File.OpenError.FileNotFound){
            stdout.writer().print(colors.GREEN ++ "Creating command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
            _ = cwd.createFile("history.txt", .{}) catch {
                stdout.writer().print(colors.RED ++ "Unable to create command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
                return;
            };
            return;
        }
        else{
            stdout.writer().print(colors.RED ++ "Unable to open command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
            return;
        }
    };
    for(cmd_history.items) |cmd| {
        var cmd_with_newline = try std.mem.concat(globAlloc, u8, &[_][]const u8{cmd, "\n"});
        _ = cmd_history_file.write(cmd_with_newline) catch {
            stdout.writer().print(colors.RED ++ "Unable to write to command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
            return;
        };
    }

}

///Open 'history.txt' file and populate the cmd_history global with the command history
pub fn loadCmdHistory() !void {
    const cwd = std.fs.cwd();
    cmd_history = std.ArrayList([] const u8).init(globAlloc);
    var cmd_history_file = cwd.openFile("history.txt", .{}) catch |err| {
        if(err == std.fs.File.OpenError.FileNotFound){
            stdout.writer().print(colors.GREEN ++ "Creating command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
            _ = cwd.createFile("history.txt", .{}) catch {
                stdout.writer().print(colors.RED ++ "Unable to create command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
                return;
            };
            return;
        }
        else{
            stdout.writer().print(colors.RED ++ "Unable to open command history file" ++ colors.DEFAULT ++ "\n", .{}) catch {};
            return;
        }
    };
    var file_buf = try cmd_history_file.readToEndAlloc(globAlloc, std.math.maxInt(u32));
    var cmd_iterator = std.mem.tokenize(u8, file_buf, "\n");
    while(cmd_iterator.next()) |cmd| {
        try cmd_history.append(cmd);
    }
}

pub fn appendCmdToHist(args: [][]const u8) !void {
    var line = std.ArrayList(u8).init(globAlloc);
    defer line.deinit();
    for(args) |arg, i| {
        try line.appendSlice(arg);
        if(i != args.len-1)
            try line.append(' ');
    }
    _ = try cmd_history.append(line.toOwnedSlice());
    cmd_index = cmd_history.items.len;
}

pub fn setGlobAlloc(alloc: std.mem.Allocator) void {
    globAlloc = alloc;
}

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

pub fn parseCommands(args: [][]const u8, pCpu: *CPU, dup: bool) !void {
    if (cmd_map.get(args[0])) |cmd| {
        switch (cmd.callback) {
            .with_cpu => {
                cmd.callback.with_cpu(pCpu, args);
            },
            .without_cpu => {
                cmd.callback.without_cpu(args);
            },
        }
        if(!std.mem.eql(u8, cmd.help_msg.cmd, "quit") and !dup)
            _ = try appendCmdToHist(args);
    } else {
        try stdout.writer().print(colors.RED ++ "Invalid command '{s}'" ++ colors.DEFAULT ++ "\n", .{args[0]});
        if(!dup)
            _ = try appendCmdToHist(args);
    }
}

pub fn getUniqueCmds() []CmdStruct {
    var unique_cmds = std.ArrayList(CmdStruct).init(globAlloc);
    defer unique_cmds.deinit();
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
    defer all_keys.deinit();
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

fn sigint_handler(int: c_int) callconv(.C) void {
    _ = int;
    glob_broken.* = true;
}

pub fn print_trace() void {
    var killme: [20]usize = .{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, };
    var trace_p: std.builtin.StackTrace = .{ .index = 0 , .instruction_addresses = &killme};
    gimmeTrace(&trace_p);
    std.debug.dumpStackTrace(trace_p);
}

fn gimmeTrace(trace: *std.builtin.StackTrace) void {
    std.debug.captureStackTrace(@returnAddress(), trace);
}

pub fn handle_sigint(broken: *bool) void {
    _ = std.os.SIG.INT;
    var mysigset: std.os.sigset_t  = std.os.empty_sigset;
    std.os.linux.sigaddset(&mysigset, std.os.SIG.INT);
    const act: std.os.Sigaction = .{
        .handler = .{
            .handler = sigint_handler
        },
        .mask = mysigset,
        .flags = std.os.SA.RESTART,
    };

    std.os.sigaction(std.os.SIG.INT, &act, null) catch {
        _ = stdout.writer().write(colors.RED ++ "Failed to hook SIGINT" ++ colors.DEFAULT ++ "\n") catch {};
    };
    glob_broken = broken;
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

pub fn promptWithArrows(alloc: std.mem.Allocator) ![][]const u8 {
    var stdin_reader = stdin.reader();
    var stdout_writer = stdout.writer();
    var read_in: u8 = undefined; 
    var line = std.ArrayList(u8).init(alloc);
    defer line.deinit();
    _ = try stdout_writer.write(prompt_str);
    while(true) {
        std.time.sleep(10000); //slow down the reads...
        read_in = stdin_reader.readByte() catch 0;
        if(read_in == 0) {
            if (glob_broken.*) {
                    glob_broken.* = false;
                    _ = line.toOwnedSlice();
                    _ = try stdout_writer.print("\r\n" ++ prompt_str ++ "{s}", .{line.items});
            }
            continue; 
        }
        switch(read_in){
            //Backspace
            '\x7f' => {
                if(line.items.len > 0){
                    _ = line.pop();
                    _ = try stdout_writer.write("\x1b[D\x1b[K\x1b[D\x1b[K\x1b[D\x1b[K");
                }
                else
                    _ = try stdout_writer.write("\x1b[D\x1b[K\x1b[D\x1b[K");
            },
            //Clear screen
            '\x0c' => {
                _ = try stdout_writer.print("\x1bc\r" ++ prompt_str ++ "{s}", .{line.items});
                continue;
            },
            //arrows!
            '\x1b' => {
                _ = stdin_reader.readByte() catch 0;
                read_in = stdin_reader.readByte() catch 0;
                const up: bool = true;
                const down: bool = false;
                _ = switch (read_in) {
                    'A' => blk: {
                        //up
                        //Move cursor left 4 and clear line after
                        _ = try stdout_writer.write("\x1b[1000D\x1b[0K");
                        line.clearAndFree();
                        _ = try line.appendSlice(getCmdFromHistory(up));
                        _ = try stdout_writer.print("\x1b2K\r" ++ prompt_str ++ "{s}", .{line.items});
                        break :blk line.items;
                    },
                    'B' => blk: {
                        //down
                        _ = try stdout_writer.write("\x1b[1000D\x1b[0K");
                        line.clearAndFree();
                        _ = try line.appendSlice(getCmdFromHistory(down));
                        _ = try stdout_writer.print("\x1b2K\r" ++ prompt_str ++  "{s}", .{line.items});
                        break :blk line.items;
                    },
                    'C' => blk: {
                        //right
                        _ = try stdout_writer.write("\x1b[4D\x1b[0K");
                        break :blk line.items;
                    },
                    'D' => blk: { 
                        //left
                        _ = try stdout_writer.write("\x1b[5D\x1b[0K");
                        break :blk line.items;
                    },
                    else => "\x00",
                };
                //try stdout.writer().print("\rarrow type: {s}\n> ", .{line.toOwnedSlice()});
                continue;
            },
            '\n' => {
                var cmd_iterator = std.mem.tokenize(u8, line.toOwnedSlice(), " ");
                var cmd_list = std.ArrayList([] const u8).init(alloc);
                defer cmd_list.deinit();
                while (cmd_iterator.next()) |arg| {
                    try cmd_list.append(arg);
                }
                if (cmd_list.items.len == 0) {
                    try cmd_list.append("");
                }
                return cmd_list.toOwnedSlice();
            },
            //ASCII printable range...
            0x20...0x7e => {
                try line.append(read_in);
            },
            //EOT (Ctrl + D)
            0x04 => {
                _ = line.toOwnedSlice();
                var cmd_list = std.ArrayList([] const u8).init(alloc);
                _ = try stdout_writer.print("\r\n", .{});
                defer cmd_list.deinit();
                try cmd_list.append("quit");
                return cmd_list.toOwnedSlice();
            },
            else => {
                if (glob_broken.*) {
                    glob_broken.* = false;
                    _ = line.toOwnedSlice();
                    _ = try stdout_writer.print("\r\n" ++ prompt_str ++ "{s}", .{line.items});
                }
                continue;
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
    defer cmdList.deinit();

    while (cmdIterator.next()) |arg| {
        try cmdList.append(arg);
    }
    if (cmdList.items.len == 0) {
        try cmdList.append("");
    }
    return cmdList.toOwnedSlice();
}
