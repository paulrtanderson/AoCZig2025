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
    var row_index: usize = 1;
    while (try r.takeDelimiter('\n')) |line| : (_ = r.discardDelimiterInclusive('\n') catch {}) { // skip every other line
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
                else => {
                    std.debug.panic("Unexpected character: {d}\n on line {d}: {s} at column {d}", .{ char, row_index, line, column });
                },
            }
        }
        row_index += 1;
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

fn timeIterative(context: IterativeArgs, _: std.mem.Allocator) !u64 {
    var reader: std.Io.Reader = .fixed(context.data);
    var timer: std.time.Timer = try .start();
    const res = try part1and2(&reader);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

const RecursiveArgs = struct {
    data: []const u8,
};

fn timeRecursive(context: RecursiveArgs, allocator: std.mem.Allocator) !u64 {
    var timer: std.time.Timer = try .start();
    const res = try part2recursive(allocator, context.data);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

pub fn benchmark(allocator: std.mem.Allocator, backing_allocator: std.mem.Allocator, io: std.Io, filepath: []const u8, stdout: *std.Io.Writer, runs: u32) !void {
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);
    const input_data = file_data[0 .. file_data.len - 1];

    try utils.benchmarkGeneric(allocator, backing_allocator, IterativeArgs{ .data = input_data }, timeIterative, "Part 1 & 2 Iterative", stdout, runs);
    try stdout.flush();
    try utils.benchmarkGeneric(allocator, backing_allocator, RecursiveArgs{ .data = input_data }, timeRecursive, "Part 2 Recursive", stdout, runs);
    try stdout.flush();
    std.debug.print("finished the benchmark\n", .{});
}

pub fn run(io: std.Io, stdout: *std.Io.Writer, filepath: []const u8) !void {
    const dir = std.Io.Dir.cwd();

    const answer1, const answer2 = blk: {
        const file = try dir.openFile(io, filepath, .{});
        defer file.close(io);
        var file_buffer: [1000]u8 = undefined;
        var reader = file.reader(io, &file_buffer);
        break :blk try part1and2(&reader.interface);
    };

    try stdout.print("Answer part 1: {d}\n", .{answer1});
    try stdout.print("Answer part 2: {d}\n", .{answer2});

    try stdout.flush();
}

const day7_data = @import("data").data_2025.day7;
const embedded_input = day7_data.input;
const embedded_example = day7_data.example;

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

fn checkRun(input_path: []const u8, expected_part1: u64, expected_part2: u64) !void {
    const allocator = std.testing.allocator;
    var allocating_writer: std.Io.Writer.Allocating = .init(allocator);
    defer allocating_writer.deinit();
    const writer = &allocating_writer.writer;
    try run(std.testing.io, writer, input_path);
    const output = try allocating_writer.toOwnedSlice();
    defer allocator.free(output);

    const part1_str = try std.fmt.allocPrint(allocator, "{d}", .{expected_part1});
    defer allocator.free(part1_str);
    const part2_str = try std.fmt.allocPrint(allocator, "{d}", .{expected_part2});
    defer allocator.free(part2_str);

    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, part1_str));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, part2_str));
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

test "run" {
    try checkRun(day7_data.example_path_str, part1_example_expected, part2_example_expected);
    try checkRun(day7_data.input_path_str, part1_real_expected, part2_real_expected);
}
