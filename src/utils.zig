const std = @import("std");

pub const Range = struct { start: u64, end: u64 };

pub fn getRange(range_string: []const u8) !Range {
    var dash_index: usize = 0;
    while (dash_index < range_string.len) : (dash_index += 1) {
        if (range_string[dash_index] == '-') {
            break;
        }
    }
    const start = std.fmt.parseInt(u64, range_string[0..dash_index], 10) catch |err| {
        std.debug.print("Error: {} Failed to parse start from range string: '{s}' with start as '{s}'\n", .{ err, range_string, range_string[0..dash_index] });
        return err;
    };

    const end = std.fmt.parseInt(u64, range_string[dash_index + 1 ..], 10) catch |err| {
        std.debug.print("Error: {} Failed to parse end from range string: '{s}' with end as '{s}'\n", .{ err, range_string, range_string[dash_index + 1 ..] });
        return err;
    };

    const myRange = Range{ .start = start, .end = end };
    return myRange;
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

pub fn benchmarkGeneric(
    allocator: std.mem.Allocator,
    backing_allocator: std.mem.Allocator,
    context: anytype,
    comptime runFn: *const fn (@TypeOf(context), std.mem.Allocator) anyerror!u64,
    label: []const u8,
    stdout: *std.Io.Writer,
    runs: u32,
) !void {
    var arena = std.heap.ArenaAllocator.init(backing_allocator);
    defer arena.deinit();

    // Warmup
    const warmup_runs = runs / 10;
    for (0..warmup_runs) |_| {
        const res = runFn(context, arena.allocator());
        std.mem.doNotOptimizeAway(res);
        _ = arena.reset(.retain_capacity);
    }

    // Benchmarking
    const run_times = try allocator.alloc(u64, runs);
    defer allocator.free(run_times);

    for (0..runs) |i| {
        const res = try runFn(context, arena.allocator());
        run_times[i] = res;
        _ = arena.reset(.retain_capacity);
    }

    try stdout.print("\n=======================\n", .{});
    try stdout.print("Benchmark results for {s}:\n", .{label});
    try printStats(run_times, stdout);
}
