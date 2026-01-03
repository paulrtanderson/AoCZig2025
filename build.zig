const std = @import("std");

pub fn build(b: *std.Build) void {
    const run_step = b.step("run", "Run the app");
    const test_step = b.step("test", "Run tests");
    const check = b.step("check", "Check if aoc compiles");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const utils_module = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
    });
    const data_module = b.createModule(.{
        .root_source_file = b.path("data/data.zig"),
    });
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    root_module.addImport("utils", utils_module);
    root_module.addImport("data", data_module);

    // main executable
    const exe = b.addExecutable(.{
        .name = "aoc",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
    // so that `zig build run` can accept args
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};
    // tests start from the root module as well
    const exe_tests = b.addTest(.{ .root_module = exe.root_module, .filters = test_filters });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    test_step.dependOn(&run_exe_tests.step);

    b.step("debug-test-unit", "Debug unit tests").dependOn(&b.addInstallArtifact(exe_tests, .{ .dest_sub_path = "debug-unit-tests" }).step);

    // check step for ZLS
    check.dependOn(&exe.step);
    check.dependOn(&exe_tests.step);
}
