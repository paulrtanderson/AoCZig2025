const std = @import("std");
var timer: std.time.Timer = undefined;
const filepath = "data/2025/day3/input.txt";
const utils = @import("utils");

pub fn part1(inputData: []const u8) u64 {
    var it = std.mem.tokenizeScalar(u8, inputData, '\n');

    var total: u64 = 0;
    while (it.next()) |line| {
        const arg_max = std.sort.argMax(u8, line[0 .. line.len - 1], {}, std.sort.asc(u8)) orelse unreachable;
        const max_value = line[arg_max];

        std.debug.assert(max_value >= '0' and max_value <= '9');

        const arg_max_after = std.sort.argMax(u8, line[arg_max + 1 .. line.len], {}, std.sort.asc(u8)) orelse unreachable;
        const max_value_after = line[arg_max + 1 + arg_max_after];

        std.debug.assert(max_value_after >= '0' and max_value_after <= '9');

        const digit1 = max_value - '0';
        const digit2 = max_value_after - '0';

        total += digit1 * 10 + digit2;
    }
    return total;
}

pub fn part2(inputData: []const u8) u64 {
    var it = std.mem.tokenizeScalar(u8, inputData, '\n');

    var total: u64 = 0;

    const number_of_digits = 12;
    var buffer: [number_of_digits]u8 = undefined;

    while (it.next()) |line| {
        var previous_max_index: usize = 0;
        for (0..number_of_digits) |i| {
            const max_arg = std.sort.argMax(u8, line[previous_max_index .. line.len - (number_of_digits - 1 - i)], {}, std.sort.asc(u8)) orelse unreachable;
            const max_value = line[previous_max_index + max_arg];

            std.debug.assert(max_value >= '0' and max_value <= '9');

            previous_max_index += max_arg + 1;
            buffer[i] = max_value;
        }

        total += std.fmt.parseInt(u64, &buffer, 10) catch unreachable;
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
    const answer2 = part2(inputData);
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

const embedded_input = @import("data").data_2025.day3.input;
const embedded_example = @import("data").data_2025.day3.example;

const trimmed_input = embedded_input[0 .. embedded_input.len - 1];
const trimmed_example = embedded_example[0 .. embedded_example.len - 1];

const part1_example_expected = 357;
const part2_example_expected = 3121910778619;

const part1_real_expected = 17100;
const part2_real_expected = 170418192256861;

test "part1 example" {
    const result = part1(trimmed_example);
    try std.testing.expectEqual(part1_example_expected, result);
}

test "part1 actual" {
    const result = part1(trimmed_input);
    try std.testing.expectEqual(part1_real_expected, result);
}

test "part2 example" {
    const result = part2(trimmed_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    const result = part2(trimmed_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
