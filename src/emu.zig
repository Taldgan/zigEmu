const std = @import("std");
const icpu = @import("cpu");
const icli = @import("cli");

///main
pub fn main() !void {
    //Arena Allocator init & defer denit
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    while (true) {
        _ = try icli.prompt(alloc);
    }
}
