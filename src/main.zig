const std = @import("std");
const aoc = @import("aoc");
const day1 = @import("2025/day1/solution.zig");
const day2 = @import("2025/day2/solution.zig");
const day3 = @import("2025/day3/solution.zig");
const day4 = @import("2025/day4/solution.zig");
const day5 = @import("2025/day5/solution.zig");
const day6 = @import("2025/day6/solution.zig");

const builtin = @import("builtin");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const gpa, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };

    var threaded: std.Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();

    defer if (is_debug) {
        std.debug.assert(debug_allocator.deinit() == .ok);
    };

    var args_iter = try std.process.argsWithAllocator(gpa);
    defer args_iter.deinit();

    // Skip argv[0]
    _ = args_iter.next();

    if (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "day1")) {
            try day1.run(threaded.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day2")) {
            try day2.run(threaded.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day3")) {
            try day3.run(threaded.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day4")) {
            try day4.run(threaded.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day5")) {
            try day5.run(threaded.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day6")) {
            try day6.run(threaded.io(), gpa);
        } else {
            std.debug.print("Unknown day: {s}\n", .{arg});
        }
    } else {
        std.debug.print("Usage: aoc <day>\n", .{});
    }
}

test {
    std.testing.refAllDecls(@This());
}
