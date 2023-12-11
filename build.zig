const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const colorsModule = b.addModule("colors", .{ .source_file = .{ .path = "lib/colors.zig" } });

    const cpuModule = b.addModule("cpu", .{ .source_file = .{ .path = "lib/cpu.zig" } });

    const cliModule = b.addModule("cli", .{ .source_file = .{ .path = "lib/cli.zig" } });

    const exe = b.addExecutable(.{
        .name = "zigEmu",
        .root_source_file = .{ .path = "src/emu.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("colors", colorsModule);
    exe.addModule("cli", cliModule);
    exe.addModule("cpu", cpuModule);
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
