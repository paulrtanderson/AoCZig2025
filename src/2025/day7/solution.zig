const std = @import("std");
const assert = std.debug.assert;

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

pub fn part1and2(input_data: []const u8) struct { u64, u64 } {
    var it = std.mem.splitScalar(u8, input_data, '\n');
    const first_line = it.next().?;

    const columns_upper_bound = 256;
    assert(first_line.len <= columns_upper_bound);

    var beam_timelines_buffer: [columns_upper_bound]usize = @splat(0);
    var beam_timelines_columns = beam_timelines_buffer[0..first_line.len];

    beam_timelines_columns[std.mem.findScalar(u8, first_line, 'S').?] = 1;

    _ = it.next();

    var num_splits: usize = 0;
    while (it.next()) |line| {
        _ = it.next();
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

fn recursiveCount(lines: []const []const u8, column: usize, row: usize, memo: *std.AutoHashMap(usize, u64)) u64 {
    if (row >= lines.len) {
        return 1;
    }

    const line = lines[row];
    if (line[column] == '^') {
        const key = row * line.len + column;
        if (memo.get(key)) |cached| {
            return cached;
        }
        const left = recursiveCount(lines, column - 1, row + 1, memo);
        const right = recursiveCount(lines, column + 1, row + 1, memo);
        const total = left + right;
        memo.put(key, total) catch {};
        return total;
    } else {
        return recursiveCount(lines, column, row + 1, memo);
    }
}

pub fn benchmark1and2(input_data: []const u8) !void {
    const runs = 10000;

    var r: std.Io.Reader = .fixed(input_data);
    //warmup
    for (0..runs) |_| {
        r = .fixed(input_data);
        const part1, const part2 = part1and2(input_data);
        std.mem.doNotOptimizeAway(part1);
        std.mem.doNotOptimizeAway(part2);
        assert(part1 == part1_real_expected);
        assert(part2 == part2_real_expected);
    }

    var run_times: [runs]u64 = @splat(0);

    for (0..runs) |i| {
        r = .fixed(input_data);
        var timer = std.time.Timer.start() catch unreachable;
        const part1, const part2 = part1and2(input_data);
        const time = timer.read();
        run_times[i] = time;
        std.mem.doNotOptimizeAway(part1);
        std.mem.doNotOptimizeAway(part2);
    }

    // mean and stddev
    var total: f64 = 0;
    for (run_times) |time| {
        total += @floatFromInt(time);
    }
    const mean = total / runs;

    var variance_total: f64 = 0;
    for (run_times) |time| {
        const ftime: f64 = @floatFromInt(time);
        const diff = ftime - mean;
        variance_total += diff * diff;
    }
    const variance = variance_total / runs;
    const stddev = std.math.sqrt(variance);
    const min_index, const max_index = std.mem.findMinMax(u64, &run_times);
    const min = run_times[min_index];
    const max = run_times[max_index];

    std.mem.sort(u64, &run_times, {}, std.sort.asc(u64));

    const median: f64 = if (runs % 2 == 0)
        (@as(f64, @floatFromInt(run_times[runs / 2 - 1])) + @as(f64, @floatFromInt(run_times[runs / 2]))) / 2.0
    else
        @floatFromInt(run_times[runs / 2]);
    std.debug.print("Benchmark Part 1 and 2 over {d} runs:\n", .{runs});
    std.debug.print("Mean time: {d:.2} ns\n", .{mean});
    std.debug.print("Median time: {d:.2} ns\n", .{median});
    std.debug.print("Standard Deviation: {d:.2} ns\n", .{stddev});
    std.debug.print("Min time: {d} ns at run {d}\n", .{ min, min_index });
    std.debug.print("Max time: {d} ns at run {d}\n", .{ max, max_index });
}

pub fn readerVersion(r: *std.Io.Reader) !struct { u64, u64 } {
    const first_line = try r.takeDelimiter('\n') orelse unreachable;

    const columns_upper_bound = 256;
    assert(first_line.len <= columns_upper_bound);

    var beam_timelines_buffer: [columns_upper_bound]usize = @splat(0);
    var beam_timelines_columns = beam_timelines_buffer[0..first_line.len];

    beam_timelines_columns[std.mem.findScalar(u8, first_line, 'S').?] = 1;

    _ = r.discardDelimiterInclusive('\n') catch {};

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

pub fn part2recursive(allocator: std.mem.Allocator, inputdata: []const u8) !u64 {
    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    const first_line = it.next().?;
    const start_column = std.mem.findScalar(u8, first_line, 'S').?;

    var lines_list = try std.ArrayList([]const u8).initCapacity(allocator, inputdata.len / first_line.len + 1);
    defer lines_list.deinit(allocator);

    while (it.next()) |line| {
        lines_list.appendAssumeCapacity(line);
    }

    var memo = std.AutoHashMap(usize, u64).init(allocator);
    try memo.ensureTotalCapacity(2000);
    defer memo.deinit();

    return recursiveCount(lines_list.items, start_column, 0, &memo);
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    var timer = std.time.Timer.start() catch unreachable;

    const start = timer.read();

    // TODO: this is probably a bad way to benchmark, maybe input data gets put in cache after the solution runs once? idk
    const filepath = "data/2025/day7/input.txt";
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);

    const inputData = file_data[0 .. file_data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer, const answer2 = part1and2(inputData);
    const end = timer.read();

    const start2 = timer.read();
    const answer2recursive = try part2recursive(allocator, inputData);
    const end2 = timer.read();

    assert(answer2 == answer2recursive);

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    try benchmark1and2(inputData);

    try stdout.print("Elapsed time (file IO): {d} ns\n", .{after_io - start});
    try stdout.print("Elapsed time (solution): {d} ns\n", .{end - after_io});
    try stdout.print("Answer: {d}\n", .{answer});

    try stdout.print("Elapsed time (part 2 recursive solution): {d} ns\n", .{end2 - start2});
    try stdout.print("Answer part 2: {d}\n", .{answer2recursive});

    try stdout.flush();
}
const embedded_input = @import("data").data_2025.day7.input;
const embedded_example = @import("data").data_2025.day7.example;

const part1_example_expected = 21;
const part2_example_expected = 40;

const part1_real_expected = 1573;
const part2_real_expected = 15093663987272;

test "part1 example" {
    const part1, const part2 = part1and2(embedded_example);
    try std.testing.expectEqual(part1_example_expected, part1);
    try std.testing.expectEqual(part2_example_expected, part2);
}

test "part1 actual" {
    const part1, const part2 = part1and2(embedded_input);
    try std.testing.expectEqual(part1_real_expected, part1);
    try std.testing.expectEqual(part2_real_expected, part2);
}

test "part2 example" {
    const result = try part2recursive(std.testing.allocator, embedded_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    const result = try part2recursive(std.testing.allocator, embedded_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
