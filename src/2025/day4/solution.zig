const std = @import("std");
const utils = @import("utils");
const readFileAlloc = utils.readFileAlloc;
var timer: std.time.Timer = undefined;
const filepath = "data/2025/day4/input.txt";
const assert = std.debug.assert;

pub fn part1(inputData: []const u8) u64 {
    var total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, inputData, '\n');

    var previous_row_maybe: ?[]const u8 = null;
    while (it.next()) |token| : (previous_row_maybe = token) {
        const next_row_maybe = it.peek();

        for (token, 0..) |cell, col| {
            assert(cell == '.' or cell == '@');

            if (cell != '@') continue;

            const left_bound = if (col == 0) 0 else col - 1;
            const right_bound = @min(col + 2, token.len);

            const upper_count: u8 = if (previous_row_maybe) |previous_row|
                @intCast(std.mem.countScalar(u8, previous_row[left_bound..right_bound], '@'))
            else
                0;

            const lower_count: u8 = if (next_row_maybe) |next_row|
                @intCast(std.mem.countScalar(u8, next_row[left_bound..right_bound], '@'))
            else
                0;

            const left_el: u1 = if (col > 0 and token[col - 1] == '@') 1 else 0;
            const right_el: u1 = if (col + 1 < token.len and token[col + 1] == '@') 1 else 0;

            const s = upper_count + left_el + right_el + lower_count;
            if (s < 4) total += 1;
        }
    }
    return total;
}

// repeatedly removes rolls until stable
// a more efficient implementation would do this in one pass
// but this would require memory allocation in order to cheaply backtrack
pub fn part2(inputData: []u8) u64 {
    var total: u64 = 0;
    while (true) {
        const subtotal = removeRolls(inputData);
        total += subtotal;
        if (subtotal == 0) break;
    }

    return total;
}

fn removeRolls(rolls: []u8) u64 {
    var total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, rolls, '\n');

    var previous_row_maybe: ?[]const u8 = null;
    while (it.next()) |token_const| : (previous_row_maybe = token_const) {
        // this is safe because the underlying buffer comes from rolls: []u8 which is mutable
        // the slice also doesn't include any delimiters so it shouldn't affect the tokenize iterator
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

            const lower_count: u8 = if (next_row_maybe) |next_row|
                @intCast(std.mem.countScalar(u8, next_row[left_bound..right_bound], '@'))
            else
                0;

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
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);

    const inputData = file_data[0 .. file_data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = part1(inputData);
    const end = timer.read();

    const start2 = timer.read();
    const answer2 = part2(file_data[0 .. file_data.len - 1]); // remove trailing newline
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

const embedded_input = @import("data").data_2025.day4.input;
const embedded_example = @import("data").data_2025.day4.example;

const trimmed_input = embedded_input[0 .. embedded_input.len - 1];
const trimmed_example = embedded_example[0 .. embedded_example.len - 1];

const part1_example_expected = 13;
const part2_example_expected = 43;

const part1_real_expected = 1549;
const part2_real_expected = 8887;

test "part1 example" {
    const result = part1(trimmed_example);
    try std.testing.expectEqual(part1_example_expected, result);
}

test "part1 actual" {
    const result = part1(trimmed_input);
    try std.testing.expectEqual(part1_real_expected, result);
}

test "part2 example" {
    var mutable_example: [trimmed_example.len]u8 = undefined;
    @memcpy(&mutable_example, trimmed_example);
    const result = part2(&mutable_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    var mutable_input: [trimmed_input.len]u8 = undefined;
    @memcpy(&mutable_input, trimmed_input);
    const result = part2(&mutable_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
