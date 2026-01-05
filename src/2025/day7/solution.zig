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
        _ = try r.discardDelimiterInclusive('\n');
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

const Stats = struct {
    mean: f64,
    median: f64,
    stddev: f64,
    min_index: usize,
    max_index: usize,
};

fn calculateStats(times: []u64) Stats {
    var total: f64 = 0;
    for (times) |time| {
        total += @floatFromInt(time);
    }
    const flen: f64 = @floatFromInt(times.len);
    const mean = total / flen;

    var variance_total: f64 = 0;
    for (times) |time| {
        const ftime: f64 = @floatFromInt(time);
        const diff = ftime - mean;
        variance_total += diff * diff;
    }
    const variance = variance_total / flen;
    const stddev = std.math.sqrt(variance);

    const min_index, const max_index = std.mem.findMinMax(u64, times);

    std.mem.sort(u64, times, {}, std.sort.asc(u64));

    const median: f64 = if (times.len % 2 == 0)
        (@as(f64, @floatFromInt(times[times.len / 2 - 1])) + @as(f64, @floatFromInt(times[times.len / 2]))) / 2.0
    else
        @floatFromInt(times[times.len / 2]);

    return .{ .mean = mean, .median = median, .stddev = stddev, .min_index = min_index, .max_index = max_index };
}

pub fn printStats(times: []u64, stdout: *std.Io.Writer) !void {
    const stats = calculateStats(times);
    try stdout.print("Mean time: {d:.2} ns\n", .{stats.mean});
    try stdout.print("Median time: {d:.2} ns\n", .{stats.median});
    try stdout.print("Standard Deviation: {d:.2} ns\n", .{stats.stddev});
    try stdout.print("Min time: {d} ns at run {d}\n", .{ times[0], stats.min_index });
    try stdout.print("Max time: {d} ns at run {d}\n", .{ times[times.len - 1], stats.max_index });
}

pub fn benchmark(input_data: []const u8, stdout: *std.Io.Writer) !void {
    const runs = 10000;
    const warmup_runs = 1000;
    var r: std.Io.Reader = .fixed(input_data);
    //warmup
    for (0..warmup_runs) |_| {
        r = .fixed(input_data);
        const part1, const part2 = try part1and2(&r);
        std.mem.doNotOptimizeAway(part1);
        std.mem.doNotOptimizeAway(part2);
    }

    var run_times: [runs]u64 = @splat(0);

    for (0..runs) |i| {
        r = .fixed(input_data);
        var timer = std.time.Timer.start() catch unreachable;
        const part1, const part2 = try part1and2(&r);
        const time = timer.read();
        run_times[i] = time;
        std.mem.doNotOptimizeAway(part1);
        std.mem.doNotOptimizeAway(part2);
    }

    try stdout.print("\n==============================\n", .{});
    try stdout.print("Part 1 & 2 Benchmark:\n", .{});
    try stdout.print("==============================\n", .{});
    try printStats(&run_times, stdout);

    var buffer: [65536]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buffer);
    const allocator = fba.allocator();

    // warmup
    for (0..warmup_runs) |_| {
        fba.reset();
        const result = try part2recursive(allocator, input_data);
        std.mem.doNotOptimizeAway(result);
    }

    for (0..runs) |i| {
        fba.reset();
        var timer = std.time.Timer.start() catch unreachable;
        const result = try part2recursive(allocator, input_data);
        const time = timer.read();
        std.mem.doNotOptimizeAway(result);
        run_times[i] = time;
    }
    try stdout.print("\n==============================\n", .{});
    try stdout.print("Part 2 Recursive Benchmark:\n", .{});
    try stdout.print("==============================\n", .{});

    try printStats(&run_times, stdout);
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    const filepath = "data/2025/day7/input.txt";
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);
    const input_data = file_data[0 .. file_data.len - 1]; // remove trailing newline
    var r: std.Io.Reader = .fixed(input_data);

    const answer, const answer2 = try part1and2(&r);

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);

    const stdout = &stdout_writer.interface;

    try stdout.print("Answer part 1: {d}\n", .{answer});
    try stdout.print("Answer part 2: {d}\n", .{answer2});

    try stdout.flush();

    try benchmark(input_data, stdout);

    try stdout.flush();
}
const embedded_input = @import("data").data_2025.day7.input;
const embedded_example = @import("data").data_2025.day7.example;

const part1_example_expected = 21;
const part2_example_expected = 40;

const part1_real_expected = 1573;
const part2_real_expected = 15093663987272;

test "part 1 & 2 example" {
    var r: std.Io.Reader = .fixed(embedded_example);
    const part1, const part2 = try part1and2(&r);
    try std.testing.expectEqual(part1_example_expected, part1);
    try std.testing.expectEqual(part2_example_expected, part2);
}

test "part 1 & 2 actual" {
    var r: std.Io.Reader = .fixed(embedded_input);
    const part1, const part2 = try part1and2(&r);
    try std.testing.expectEqual(part1_real_expected, part1);
    try std.testing.expectEqual(part2_real_expected, part2);
}

test "part2 recursive example" {
    const result = try part2recursive(std.testing.allocator, embedded_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 recursive actual" {
    const result = try part2recursive(std.testing.allocator, embedded_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
