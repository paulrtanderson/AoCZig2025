const std = @import("std");
const readFileAlloc = @import("filehelper").readFileAlloc;
var timer: std.time.Timer = undefined;
const filepath = "src/day5/input.txt";
const day2 = @import("../day2/solution.zig");
const getRange = day2.getRange;
const Range = day2.Range;

pub fn part1(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var arr: std.ArrayList(Range) = try .initCapacity(gpa, 100);
    defer arr.deinit(gpa);

    var it = std.mem.splitScalar(u8, inputdata, '\n');
    var half_way = false;
    var count: u64 = 0;
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "")) {
            half_way = true;
            continue;
        }
        if (!half_way) {
            const range = try getRange(token);
            try arr.append(gpa, range);
        } else {
            const num = try std.fmt.parseInt(u64, token, 10);
            var fresh = false;
            for (arr.items) |item| {
                if (inRange(num, item)) {
                    fresh = true;
                    break;
                }
            }
            if (fresh) count += 1;
        }
    }
    return count;
}

fn inRange(num: u64, range: Range) bool {
    if (num < range.start or num > range.end) return false;
    return true;
}

pub fn part2(inputdata: []const u8) u64 {
    _ = inputdata;
    return 0;
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

    const start2 = timer.read();
    const answer2 = part2(file_data.buffer[0 .. file_data.data.len - 1]); // remove trailing newline
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
