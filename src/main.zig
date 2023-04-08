const std = @import("std");
const ccpu = @import("cpu");
const print = std.debug.print;
const File = std.fs.File;

fn readEmuFile(file_name: []const u8, mem: []u8) !void {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile(file_name, .{});
    defer file.close();
    //const file_reader: std.io.Reader = file.reader();
    //Memory is actually 0x4000 in size, so want to read in and allocate at LEAST that large of a buffer
    _ = try file.readAll(mem);
}

pub fn main() !void {
    var arg_it = std.process.args();
    _ = arg_it.skip();
    //ArgIterator.next() could possibly return a null value - which means
    //the type it will return must be an 'optional' ?[]const u8
    //To counteract this, we use an if
    //In the following if, we check if the 'file_name' that
    //came from the iterator is null
    //If it isn't, then it will execute the block and assign the
    //pointer value to |name|. Name is now NOT an optional, and also guaranteed
    //to have a non-null value ([]u8)
    const file_name = arg_it.next();
    if (file_name) |name| {
        print("Opening file {s} for emulation\n", .{name});
        //Create arena allocator 'arena'
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const alloc = arena.allocator();

        //defer means execute at end of scope (main in this case)
        //Arena allocators deinit ALL memory allocated using it
        //once deinit() is called
        defer arena.deinit();
        var mem = try alloc.alloc(u8, 0x4000);
        //Zero out memory
        for (mem) |_, i| {
            mem[i] = 0;
        }

        try readEmuFile(name, mem);
        //disassembleWholeProg(mem);
        var cpu = try ccpu.initCpu(mem, alloc);
        var inst_count: u64 = 0;
        while (true) {
            ccpu.printCpuStatus(cpu);
            ccpu.emulate(cpu);
            inst_count += 1;
            print("Instructions Executed: {d}\n", .{inst_count});
        }
    }
}
