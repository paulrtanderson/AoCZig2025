var input = @embedFile("input.txt");
const std = @import("std");
const assert = std.debug.assert;
const filepath = "src/day1/input.txt";

pub fn impl1() !void {
    var ended_on_zero_count: u32 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var clicked_onto_zero_count: u32 = 0;
    var dial: u8 = 50;

    while (it.next()) |line| {
        assert(dial < 100);

        const num = std.fmt.parseInt(u32, line[1..], 10) catch unreachable;
        assert(num != 0 and num <= 1000);

        var zeros_passed: u32 = undefined;

        //std.debug.print("Processing line: {s}, num: {d}, start: {d}\n", .{ line, num, start });
        if (line[0] == 'R') {
            zeros_passed = @divFloor(dial + num, 100);
            dial = @intCast(@mod(dial + num, 100));
        } else if (line[0] == 'L') {
            const inverted = if (dial == 0) 0 else 100 - dial;
            zeros_passed = @divFloor(inverted + num, 100);
            dial = @intCast(@mod(@as(i32, @intCast(dial)) - @as(i32, @intCast(num)), 100));
        } else {
            unreachable;
        }
        if (dial == 0) {
            ended_on_zero_count += 1;
        }
        clicked_onto_zero_count += zeros_passed;
    }

    std.debug.print("old code {d}\n", .{ended_on_zero_count});
    std.debug.print("new code {d}\n", .{clicked_onto_zero_count});
}

const readFileAlloc = @import("filehelper").readFileAlloc;

pub fn alternateWithAllocation(io: std.Io, allocator: std.mem.Allocator) !void {
    const file_data = try readFileAlloc(allocator, filepath, io);
    defer allocator.free(file_data.buffer);
    const inputData = file_data.data;

    var dial_value: isize = 50;
    var ended_on_zero_count: usize = 0;
    var clicked_onto_zero_count: usize = 0;

    var it = std.mem.tokenizeScalar(u8, inputData, '\n');
    while (it.next()) |line| {
        assert(dial_value >= 0 and dial_value < 100);

        const num = std.fmt.parseUnsigned(isize, line[1..], 10) catch unreachable;
        assert(num != 0 and num <= 1000);
        const clicks: isize = switch (line[0]) {
            'R' => num,
            'L' => -num,
            else => unreachable,
        };

        clicked_onto_zero_count += @abs(@divFloor(dial_value + clicks, 100));

        // special case: if we start on zero and go backwards, we didn't actually click onto zero
        if (dial_value == 0 and clicks < 0) clicked_onto_zero_count -= 1;

        dial_value = @mod(dial_value + clicks, 100);

        if (dial_value == 0) {
            ended_on_zero_count += 1;
            // special case: if we end on zero and went backwards, this counts as having clicked onto zero
            if (clicks < 0) {
                clicked_onto_zero_count += 1;
            }
        }
    }
    std.debug.print("old code {d}\n", .{ended_on_zero_count});
    std.debug.print("new code {d}\n", .{clicked_onto_zero_count});
}

pub fn main() !void {
    var io: std.Io.Threaded = .init_single_threaded;
    defer io.deinit();

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    try run(io, allocator);
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    try alternateWithAllocation(io, allocator);
}
