const std = @import("std");
var timer: std.time.Timer = undefined;
const filepath = "src/day3/input.txt";
const readFileAlloc = @import("../fileHelper.zig").readFileAlloc;

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
    var buffer: [12]u8 = undefined;
    while (it.next()) |line| {
        var previous_max_index: usize = 0;
        for (0..12) |i| {
            const max_arg = std.sort.argMax(u8, line[previous_max_index .. line.len - (11 - i)], {}, std.sort.asc(u8)) orelse unreachable;
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
    const file_data = try readFileAlloc(allocator, filepath, io);
    defer allocator.free(file_data.buffer);

    const inputData = file_data.data[0 .. file_data.data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = part1(inputData);
    const end = timer.read();

    const start2 = timer.read();
    const answer2 = part2(inputData);
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
