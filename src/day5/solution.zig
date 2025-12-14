const std = @import("std");
var timer: std.time.Timer = undefined;
const filepath = "src/day5/input.txt";
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
    const file_data = try readFileAlloc(allocator, filepath, io);
    defer allocator.free(file_data.buffer);

    const inputData = file_data.data[0 .. file_data.data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = try part1(allocator, inputData);
    const end = timer.read();

    const inputDatatest =
        \\3-5
        \\5-14
        \\14-14
        \\19-20
        \\
        \\
    ;
    _ = inputDatatest;

    const start2 = timer.read();
    const answer2 = try part2(allocator, inputData); // remove trailing newline
    const end2 = timer.read();

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Elapsed time (file IO): {d} ns\n", .{after_io - start});
    try stdout.print("Elapsed time (solution): {d} ns\n", .{end - after_io});
    try stdout.print("Answer: {d}\n", .{answer});

    try stdout.print("Elapsed time (part 2 solution): {d} ns\n", .{end2 - start2});
    try stdout.print("Answer part 2: {d}\n", .{answer2});

    try stdout.flush();
}

test part2 {
    const inputdata =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
    ;

    std.log.debug("running tests!", {});
    const alloc = std.testing.allocator;

    const res = part2(alloc, inputdata);

    assert(false);

    assert(res catch 0 == 14);

    std.log.debug("test passed!", {});
}
