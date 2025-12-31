const std = @import("std");

pub fn build(b: *std.Build) void {
    const run_step = b.step("run", "Run the app");
    const test_step = b.step("test", "Run tests");
    const check = b.step("check", "Check if foo compiles");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const utils_mod = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
    });
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("utils", utils_mod);

    // main executable
    const exe = b.addExecutable(.{
        .name = "aoc",
        .root_module = root_module,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // tests start from the root module as well
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    test_step.dependOn(&run_exe_tests.step);

    // check step for ZLS
    const exe_check = b.addExecutable(.{
        .name = "aoc",
        .root_module = root_module,
    });
    check.dependOn(&exe_check.step);
}
