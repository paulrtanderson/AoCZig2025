const std = @import("std");
const assert = std.debug.assert;
const aoc = @import("aoc");
const day1 = @import("2025/day1/solution.zig");
const day2 = @import("2025/day2/solution.zig");
const day3 = @import("2025/day3/solution.zig");
const day4 = @import("2025/day4/solution.zig");
const day5 = @import("2025/day5/solution.zig");
const day6 = @import("2025/day6/solution.zig");
const day7 = @import("2025/day7/solution.zig");
const day8 = @import("2025/day8/solution.zig");

const data = @import("data");
const data_2025 = data.data_2025;

const builtin = @import("builtin");

pub fn main(init: std.process.Init) !void {
    const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => true,
        .ReleaseFast, .ReleaseSmall => false,
    };
    var debug_allocator_implementation: std.heap.DebugAllocator(.{}) = .init;
    const debug_allocator = debug_allocator_implementation.allocator();

    const backing_allocator = if (is_debug) debug_allocator else std.heap.page_allocator;

    const arena = init.arena.allocator();

    const allocator = if (is_debug) debug_allocator else arena;
    defer if (is_debug) assert(debug_allocator_implementation.deinit() == .ok);

    const io = init.io;

    var args_iter = try init.minimal.args.iterateAllocator(allocator);
    defer args_iter.deinit();

    // Skip argv[0]
    _ = args_iter.next();

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    const stderr = &stderr_writer.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const year_arg = args_iter.next() orelse {
        printUsageError(stderr);
        return error.InvalidArgument;
    };
    const year = std.fmt.parseInt(usize, year_arg, 10) catch {
        printUsageError(stderr);
        return error.InvalidArgument;
    };
    if (year != 2025) {
        stderr.print("Unsupported year: {d}\n", .{year}) catch {};
        stderr.flush() catch {};
        return error.InvalidArgument;
    }

    const day_arg = args_iter.next() orelse {
        printUsageError(stderr);
        return error.InvalidArgument;
    };
    if (day_arg.len < 4 or day_arg.len > 5) {
        printUsageError(stderr);
        return error.InvalidArgument;
    }
    if (!std.mem.eql(u8, day_arg[0..3], "day")) {
        printUsageError(stderr);
        return error.InvalidArgument;
    }
    const day_str = if (day_arg.len == 4) day_arg[3..4] else day_arg[3..];

    const day = std.fmt.parseInt(usize, day_str, 10) catch {
        printUsageError(stderr);
        return error.InvalidArgument;
    };
    const benchmark_arg = args_iter.next();
    const benchmark = if (benchmark_arg) |arg| blk: {
        if (std.mem.eql(u8, arg, "benchmark")) {
            break :blk true;
        } else {
            printUsageError(stderr);
            return error.InvalidArgument;
        }
    } else false;

    const benchmark_runs = 10000;
    switch (day) {
        1 => try day1.run(io, allocator),
        2 => try day2.run(io, allocator),
        3 => try day3.run(io, allocator),
        4 => try day4.run(io, allocator),
        5 => try day5.run(io, allocator),
        6 => try day6.run(io, allocator),
        7 => {
            try day7.run(io, stdout, data_2025.day7.input_path_str);
            if (benchmark) {
                try day7.benchmark(allocator, backing_allocator, io, "data/2025/day7/input.txt", stdout, benchmark_runs);
            }
        },
        8 => try day8.run(io, allocator),
        else => {
            stderr.print("Unknown day: {d}\n", .{day}) catch {};
            stderr.flush() catch {};
            return error.InvalidArgument;
        },
    }
    std.debug.print("done running year {d} day {d}\n", .{ year, day });
}

fn printUsageError(stderr: *std.Io.Writer) void {
    stderr.print("Usage: <year> day<day number>\n", .{}) catch {};
    stderr.flush() catch {};
}

test {
    std.testing.refAllDecls(@This());
}
