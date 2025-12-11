const std = @import("std");
const aoc = @import("aoc");
const day1 = @import("day1/solution.zig");
const day2 = @import("day2/solution.zig");

const builtin = @import("builtin");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    var threaded_io: std.Io.Threaded = .init_single_threaded;
    defer threaded_io.deinit();

    const gpa = gpa: {
        if (builtin.mode == .Debug) {
            break :gpa debug_allocator.allocator();
        } else {
            break :gpa std.heap.smp_allocator;
        }
    };

    defer if (builtin.mode == .Debug) {
        std.debug.assert(debug_allocator.deinit() == .ok);
    };

    var args_iter = try std.process.argsWithAllocator(gpa);
    defer args_iter.deinit();

    // Skip argv[0]
    _ = args_iter.next();

    if (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "day1")) {
            try day1.run(threaded_io.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day2")) {
            try day2.run(threaded_io.io(), gpa);
        } else if (std.mem.eql(u8, arg, "day3")) {
            const day3 = @import("day3/solution.zig");
            try day3.run(threaded_io.io(), gpa);
        } else {
            std.debug.print("Unknown day: {s}\n", .{arg});
        }
    } else {
        std.debug.print("Usage: aoc <day>\n", .{});
    }
}
