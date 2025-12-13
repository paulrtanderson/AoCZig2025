const std = @import("std");
const readFileAlloc = @import("filehelper").readFileAlloc;
var timer: std.time.Timer = undefined;
const filepath = "src/day4/input.txt";
const assert = std.debug.assert;

pub fn part1(inputData: []const u8) u64 {
    var it = std.mem.tokenizeScalar(u8, inputData, '\n');

    var total: u64 = 0;

    var previous_row: ?[]const u8 = null;
    var row: u64 = 0;

    while (it.next()) |line| : (row += 1) {
        for (line, 0..) |c, col| {
            if (c != '@') continue;

            const left = if (col == 0) 0 else col - 1;
            const right = @min(col + 2, line.len);

            const upper: u8 = if (previous_row) |pr|
                @intCast(std.mem.countScalar(u8, pr[left..right], '@'))
            else
                0;

            const left_el: u1 = if (col > 0 and line[col - 1] == '@') 1 else 0;
            const right_el: u1 = if (col + 1 < line.len and line[col + 1] == '@') 1 else 0;

            const lower: u8 = blk: {
                if (it.peek()) |nr| {
                    break :blk @intCast(std.mem.countScalar(u8, nr[left..right], '@'));
                }
                break :blk 0;
            };

            const s = upper + left_el + right_el + lower;
            if (s < 4) total += 1;
        }

        previous_row = line;
    }

    return total;
}

test part1 {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const result = part1(input[0..]);
    std.debug.assert(result == 13);
}

pub fn part2(inputData: []u8) u64 {
    var total: u64 = 0;

    var subtotal: u64 = 1;

    while (subtotal != 0) {
        subtotal = removeRolls(inputData);
        total += subtotal;
    }

    return total;
}

fn removeRolls(rolls: []u8) u64 {
    var total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, rolls, '\n');

    var previous_row_maybe: ?[]const u8 = null;
    while (it.next()) |token_const| : (previous_row_maybe = token_const) {
        var line = @constCast(token_const);

        const next_row_maybe = it.peek();

        for (line, 0..) |*cell, col| {
            assert(cell.* == '.' or cell.* == '@');

            if (cell.* != '@') continue;

            const left_bound = if (col == 0) 0 else col - 1;
            const right_bound = @min(col + 2, line.len);

            const upper_count: u8 = if (previous_row_maybe) |previous_row|
                @intCast(std.mem.countScalar(u8, previous_row[left_bound..right_bound], '@'))
            else
                0;

            const lower_count: u8 = blk: {
                if (next_row_maybe) |next_row| {
                    break :blk @intCast(std.mem.countScalar(u8, next_row[left_bound..right_bound], '@'));
                }
                break :blk 0;
            };

            const left_el: u1 = if (col > 0 and line[col - 1] == '@') 1 else 0;
            const right_el: u1 = if (col + 1 < line.len and line[col + 1] == '@') 1 else 0;

            const s = upper_count + left_el + right_el + lower_count;
            if (s < 4) {
                cell.* = '.';
                total += 1;
            }
        }
    }

    return total;
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    timer = std.time.Timer.start() catch unreachable;

    const start = timer.read();

    // TODO: this is probably a bad way to benchmark, maybe input data gets put in cache after the solution runs once? idk
    const file_data = try readFileAlloc(allocator, filepath, io);
    defer allocator.free(file_data.buffer);

    const inputData = file_data.data[0 .. file_data.data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = part1(inputData);
    const end = timer.read();

    const start2 = timer.read();
    const answer2 = part2(file_data.buffer[0 .. file_data.data.len - 1]); // remove trailing newline
    const end2 = timer.read();

    var buffer: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&buffer);

    try stdout.interface.print("Elapsed time (file IO): {d} ns\n", .{after_io - start});
    try stdout.interface.print("Elapsed time (solution): {d} ns\n", .{end - after_io});
    try stdout.interface.print("Answer: {d}\n", .{answer});

    try stdout.interface.print("Elapsed time (part 2 solution): {d} ns\n", .{end2 - start2});
    try stdout.interface.print("Answer part 2: {d}\n", .{answer2});

    try stdout.interface.flush();
}
