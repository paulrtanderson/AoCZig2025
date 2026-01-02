const std = @import("std");
var timer: std.time.Timer = undefined;
const filepath = "data/2025/day5/input.txt";
const utils = @import("utils");
const readFileAlloc = utils.readFileAlloc;
const Range = utils.Range;
const getRange = utils.getRange;

const assert = std.debug.assert;

pub fn part1(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var it = std.mem.splitScalar(u8, inputdata, '\n');

    var arr = try processRanges(gpa, &it);
    defer arr.deinit(gpa);

    if (arr.items.len == 0) return 0;

    var count: u64 = 0;
    while (it.next()) |token| {
        const num = try std.fmt.parseInt(u64, token, 10);
        for (arr.items) |item| {
            if (inRange(num, item)) {
                count += 1;
                break;
            }
        }
    }
    return count;
}

fn compareRangeStart(_: void, r1: Range, r2: Range) bool {
    return r1.start < r2.start;
}

pub fn part2(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var it = std.mem.splitScalar(u8, inputdata, '\n');

    var arr = try processRanges(gpa, &it);
    defer arr.deinit(gpa);

    if (arr.items.len == 0) return 0;

    std.mem.sort(Range, arr.items, {}, compareRangeStart);

    var cur_start: u64 = arr.items[0].start;
    var cur_end: u64 = arr.items[0].end;

    var count = cur_end + 1 - cur_start;

    for (arr.items[1..]) |range| {
        cur_start = @max(cur_end + 1, range.start);
        cur_end = @max(cur_end, range.end);

        count += cur_end + 1 - cur_start;
    }

    return count;
}

fn processRanges(gpa: std.mem.Allocator, it_p: *std.mem.SplitIterator(u8, .scalar)) !std.ArrayList(Range) {
    var arr: std.ArrayList(Range) = try .initCapacity(gpa, 100);
    errdefer arr.deinit(gpa);
    var it = it_p.*;
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "")) {
            break;
        }
        const range = try getRange(token);
        try arr.append(gpa, range);
    }
    it_p.* = it;

    return arr;
}

fn inRange(num: u64, range: Range) bool {
    if (num < range.start or num > range.end) return false;
    return true;
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    timer = std.time.Timer.start() catch unreachable;

    const start = timer.read();

    // TODO: this is probably a bad way to benchmark, maybe input data gets put in cache after the solution runs once? idk
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);

    const inputData = file_data[0 .. file_data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = try part1(allocator, inputData);
    const end = timer.read();

    const start2 = timer.read();
    const answer2 = try part2(allocator, inputData); // remove trailing newline
    const end2 = timer.read();

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Elapsed time (file IO): {d} ns\n", .{after_io - start});
    try stdout.print("Elapsed time (solution): {d} ns\n", .{end - after_io});
    try stdout.print("Answer: {d}\n", .{answer});

    try stdout.print("Elapsed time (part 2 solution): {d} ns\n", .{end2 - start2});
    try stdout.print("Answer part 2: {d}\n", .{answer2});

    try stdout.flush();
}

const embedded_input = @import("data").data_2025.day5.input;
const embedded_example = @import("data").data_2025.day5.example;

const trimmed_input = embedded_input[0 .. embedded_input.len - 1];
const trimmed_example = embedded_example[0 .. embedded_example.len - 1];

const part1_example_expected = 3;
const part2_example_expected = 14;

const part1_real_expected = 598;
const part2_real_expected = 360341832208407;

test "part1 example" {
    const result = try part1(std.testing.allocator, trimmed_example);
    try std.testing.expectEqual(part1_example_expected, result);
}

test "part1 actual" {
    const result = try part1(std.testing.allocator, trimmed_input);
    try std.testing.expectEqual(part1_real_expected, result);
}

test "part2 example" {
    const result = try part2(std.testing.allocator, trimmed_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    const result = try part2(std.testing.allocator, trimmed_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
