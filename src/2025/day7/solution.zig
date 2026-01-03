const std = @import("std");
var timer: std.time.Timer = undefined;
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

pub fn part1and2(inputdata: []const u8) struct { u64, u64 } {
    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');

    const buffer_size: usize = 256;

    var buffer: [buffer_size]u16 = undefined;
    var buffer_prev: [buffer_size]u16 = undefined;

    var paths_buffer: [buffer_size]usize = @splat(0);

    var beam_positions_current = std.ArrayList(u16).initBuffer(&buffer);

    const source_index = std.mem.findScalar(u8, it.next().?, 'S').?;

    beam_positions_current.appendAssumeCapacity(@intCast(source_index));

    var paths_slice = paths_buffer[0..it.peek().?.len];
    paths_slice[source_index] = 1;

    var count: u32 = 0;
    while (it.next()) |line| {
        var last_beam: ?u15 = null;
        const previous_beam_slice = buffer_prev[0..beam_positions_current.items.len];
        @memcpy(previous_beam_slice, beam_positions_current.items);
        //printBeamPositions(previous_beam_slice);

        beam_positions_current.clearRetainingCapacity();
        var num_splits: u8 = 0;
        for (previous_beam_slice) |i| {
            const index: u15 = @intCast(i);
            if (line[i] == '^') {
                if (last_beam == null or last_beam.? + 1 != index) {
                    beam_positions_current.appendAssumeCapacity(index - 1);
                }

                paths_slice[i - 1] += paths_slice[i];
                paths_slice[i + 1] += paths_slice[i];
                paths_slice[i] = 0;

                beam_positions_current.appendAssumeCapacity(index + 1);
                num_splits += 1;
                last_beam = index + 1;
            } else {
                if (last_beam == null or last_beam.? != index) {
                    beam_positions_current.appendAssumeCapacity(index);
                    last_beam = index;
                } else {}
            }
        }
        count += num_splits;
    }

    var num_timelines: usize = 0;
    for (paths_slice) |p| {
        num_timelines += p;
    }

    return .{ count, num_timelines };
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
    timer = std.time.Timer.start() catch unreachable;

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

    std.debug.print("answer: {d}, answer2: {d}\n", .{ answer, answer2 });

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

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
    const result, _ = part1and2(embedded_example);
    try std.testing.expectEqual(part1_example_expected, result);
}

test "part1 actual" {
    const result, _ = part1and2(embedded_input);
    try std.testing.expectEqual(part1_real_expected, result);
}

test "part2 example" {
    const result = try part2recursive(std.testing.allocator, embedded_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    if (true) return error.SkipZigTest;
    const result = try part2recursive(std.testing.allocator, embedded_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
