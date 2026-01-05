const std = @import("std");
const assert = std.debug.assert;
const utils = @import("utils");

fn printBeamPositions(positions: []const u16) void {
    std.debug.print("Beam positions: [", .{});
    for (positions, 0..) |pos, idx| {
        if (idx != 0) {
            std.debug.print(", ", .{});
        }
        std.debug.print("{d}", .{pos});
    }
    std.debug.print("]\n", .{});
}

pub fn part1and2(r: *std.Io.Reader) !struct { u64, u64 } {
    const first_line = try r.takeDelimiter('\n') orelse unreachable;
    _ = try r.discardDelimiterInclusive('\n');

    const columns_upper_bound = 256;
    assert(first_line.len <= columns_upper_bound);

    var beam_timelines_buffer: [columns_upper_bound]usize = @splat(0);
    var beam_timelines_columns = beam_timelines_buffer[0..first_line.len];

    beam_timelines_columns[std.mem.findScalar(u8, first_line, 'S').?] = 1;

    var num_splits: usize = 0;
    while (try r.takeDelimiter('\n')) |line| {
        _ = r.discardDelimiterInclusive('\n') catch {};
        for (line, 0..) |char, column| {
            switch (char) {
                '.' => {},
                '^' => {
                    if (beam_timelines_columns[column] != 0) {
                        beam_timelines_columns[column - 1] += beam_timelines_columns[column];
                        beam_timelines_columns[column + 1] += beam_timelines_columns[column];
                        beam_timelines_columns[column] = 0;
                        num_splits += 1;
                    }
                },
                else => unreachable,
            }
        }
    }
    var num_timelines: usize = 0;
    for (beam_timelines_columns) |beam_timelines_column| {
        num_timelines += beam_timelines_column;
    }
    return .{ num_splits, num_timelines };
}

fn recursiveCount(inputdata: []const u8, stride: usize, num_rows: usize, index: usize, memo: *std.AutoHashMap(usize, u64)) u64 {
    const row = index / stride;
    if (row >= num_rows) {
        return 1;
    }

    if (inputdata[index] == '^') {
        if (memo.get(index)) |cached| {
            return cached;
        }
        const next_row_index = index + stride;
        const left = recursiveCount(inputdata, stride, num_rows, next_row_index - 1, memo);
        const right = recursiveCount(inputdata, stride, num_rows, next_row_index + 1, memo);
        const total = left + right;
        memo.putAssumeCapacity(index, total);
        return total;
    } else {
        return recursiveCount(inputdata, stride, num_rows, index + stride, memo);
    }
}

pub fn part2recursive(allocator: std.mem.Allocator, inputdata: []const u8) !u64 {
    const line_width = std.mem.indexOfScalar(u8, inputdata, '\n').?;
    const stride = line_width + 1; // include newline character
    const num_rows = (inputdata.len + 1) / stride - 1; // exclude first row (with 'S')

    const start_column = std.mem.indexOfScalar(u8, inputdata[0..line_width], 'S').?;
    const start_index = stride + start_column; // start on second row

    var memo = std.AutoHashMap(usize, u64).init(allocator);
    try memo.ensureTotalCapacity(1000);
    defer memo.deinit();

    return recursiveCount(inputdata, stride, num_rows, start_index, &memo);
}

const IterativeArgs = struct {
    data: []const u8,
};
fn timeIterative(context: IterativeArgs) !u64 {
    var reader: std.Io.Reader = .fixed(context.data);
    var timer: std.time.Timer = try .start();
    const res = try part1and2(&reader);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

const RecursiveArgs = struct {
    data: []const u8,
    allocator: std.mem.Allocator,
};
fn timeRecursive(context: RecursiveArgs) !u64 {
    var timer: std.time.Timer = try .start();
    const res = try part2recursive(context.allocator, context.data);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

pub fn benchmark(allocator: std.mem.Allocator, io: std.Io, filepath: []const u8, stdout: *std.Io.Writer) !void {
    const runs = 10000;

    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);
    const input_data = file_data[0 .. file_data.len - 1];

    try utils.benchmarkGeneric(IterativeArgs{ .data = input_data }, timeIterative, "Part 1 & 2 Iterative", stdout, runs);

    try stdout.flush();

    try utils.benchmarkGeneric(RecursiveArgs{ .data = input_data, .allocator = allocator }, timeRecursive, "Part 2 Recursive", stdout, runs);
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    const filepath = "data/2025/day7/input.txt";
    const dir = std.Io.Dir.cwd();

    const answer1, const answer2 = blk: {
        const file = try dir.openFile(io, filepath, .{});
        defer file.close(io);
        var file_buffer: [1000]u8 = undefined;
        var reader = file.reader(io, &file_buffer);
        break :blk try part1and2(&reader.interface);
    };

    var buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer part 1: {d}\n", .{answer1});
    try stdout.print("Answer part 2: {d}\n", .{answer2});

    try stdout.flush();

    try benchmark(allocator, io, filepath, stdout);

    try stdout.flush();
}
const embedded_input = @import("data").data_2025.day7.input;
const embedded_example = @import("data").data_2025.day7.example;

const part1_example_expected = 21;
const part2_example_expected = 40;

const part1_real_expected = 1573;
const part2_real_expected = 15093663987272;

fn checkIterative(data: []const u8, expected: struct { u64, u64 }) !void {
    var r: std.Io.Reader = .fixed(data);
    const part1, const part2 = try part1and2(&r);
    const part1_expected, const part2_expected = expected;
    try std.testing.expectEqual(part1_expected, part1);
    try std.testing.expectEqual(part2_expected, part2);
}

fn checkRecursive(data: []const u8, expected: u64) !void {
    const result = try part2recursive(std.testing.allocator, data);
    try std.testing.expectEqual(expected, result);
}

const example_expected = .{ part1_example_expected, part2_example_expected };
const real_expected = .{ part1_real_expected, part2_real_expected };

test "part 1 & 2 iterative" {
    try checkIterative(embedded_example, example_expected);
    try checkIterative(embedded_input, real_expected);
}

test "part2 recursive" {
    try checkRecursive(embedded_example, part2_example_expected);
    try checkRecursive(embedded_input, part2_real_expected);
}
