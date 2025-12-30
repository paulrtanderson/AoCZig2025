const std = @import("std");
const filepath = "src/day2/input.txt";
const utils = @import("utils");
const assert = std.debug.assert;
const Range = utils.Range;
const getRange = utils.getRange;

var operation_count: usize = 0;
var after_io_time: u64 = undefined;
var timer: std.time.Timer = undefined;

const dopartone = false;

const FirstSolution = struct {
    pub fn solution(inputData: []const u8) !u64 {
        var it = std.mem.tokenizeScalar(u8, inputData, ',');

        var sum_of_invalid_ids: u64 = 0;
        var sum_of_2nd_invalid_ids: u64 = 0;

        while (it.next()) |line| {
            const range = try getRange(line); // remove newline

            for (range.start..range.end + 1) |num| {
                const id: u64 = @intCast(num);
                if (dopartone) {
                    if (repeatsTwice(id)) {
                        sum_of_invalid_ids += num;
                    }
                }
                if (!isValid2(id)) {
                    sum_of_2nd_invalid_ids += num;
                }
            }
        }
        return sum_of_2nd_invalid_ids;
    }

    fn repeatsLengthN(id: u64, n: u8, num_digits: u8) bool {
        assert(id > 0 and id < 1_000_000_000_000_000);
        assert(n > 0);
        assert(num_digits / 2 >= n);
        if (num_digits % n != 0) {
            return false;
        }

        var string_buffer: [20]u8 = undefined;
        const len = std.fmt.printInt(&string_buffer, id, 10, .lower, .{});

        const first_part = string_buffer[0..n];

        for (0..len / n) |i| {
            operation_count += 1;
            if (!std.mem.eql(u8, first_part, string_buffer[i * n .. (i + 1) * n])) {
                return false;
            }
        }

        return true;
    }

    fn isValid2(id: u64) bool {
        const num_digits = numDigits(id);
        assert(num_digits > 0 and num_digits <= 15);
        const half_digits: usize = @intCast(num_digits / 2);
        for (1..half_digits + 1) |n| {
            if (repeatsLengthN(id, @intCast(n), num_digits)) {
                return false;
            }
        }
        return true;
    }

    fn repeatsTwice(id: u64) bool {
        if (numDigits(id) % 2 != 0) {
            return false;
        }

        var string_buffer: [20]u8 = undefined;
        const len = std.fmt.printInt(&string_buffer, id, 10, .lower, .{});
        const midpoint = len / 2;
        const first_half = string_buffer[0..midpoint];
        const second_half = string_buffer[midpoint..len];
        return std.mem.eql(u8, first_half, second_half);
    }
};

fn numDigits(num: u64) u8 {
    if (num == 0) return 1;

    return @intCast(std.math.log10_int(num) + 1);
}

const SmartSolution = struct {
    const MAX_DIGITS_u64: u8 = 19;

    const POW10 = blk: {
        var arr: [MAX_DIGITS_u64 + 1]u64 = undefined;
        arr[0] = 1;
        var i: usize = 1;
        while (i <= MAX_DIGITS_u64) : (i += 1) {
            arr[i] = arr[i - 1] * 10;
        }
        break :blk arr;
    };

    fn pow10(y: u8) u64 {
        assert(y <= MAX_DIGITS_u64);
        return POW10[y];
    }

    // returns the generalised repunit with r repetitions of k digit pattern
    // e.g. k=2, r=3 -> 101010
    fn generalisedRepunit(k: u8, r: u8) u64 {
        assert(k > 0);
        assert(r > 1);
        assert(k * r <= MAX_DIGITS_u64);

        const base = pow10(k);
        const numerator = pow10(k * r) - 1;
        const denominator = base - 1;

        assert(numerator % denominator == 0);
        return numerator / denominator;
    }

    pub fn solution(inputData: []const u8, allocator: std.mem.Allocator) !u64 {
        var it = std.mem.tokenizeScalar(u8, inputData, ',');

        var seen = std.AutoHashMap(u64, void).init(allocator);
        defer seen.deinit();

        // TODO: calculate upper bound on capacity needed
        try seen.ensureTotalCapacity(10000);

        var sum_of_invalid_ids: u64 = 0;

        while (it.next()) |line| {
            const range = try getRange(line); // remove newline
            const max_digits = numDigits(range.end);

            for (1..(max_digits / 2) + 1) |num_digits_in_repeating_pattern_usize| {
                const num_digits_in_repeating_pattern: u8 = @intCast(num_digits_in_repeating_pattern_usize);

                // compute smallest and largest k digit pattern where k = num_digits_in_repeating_pattern
                const pattern_min = pow10(num_digits_in_repeating_pattern - 1);
                const pattern_max = pow10(num_digits_in_repeating_pattern) - 1;
                const max_num_repetitions = @divFloor(max_digits, num_digits_in_repeating_pattern);

                for (2..max_num_repetitions + 1) |num_repetitions_usize| {
                    const num_repetitions: u8 = @intCast(num_repetitions_usize);

                    const generalised_repunit = generalisedRepunit(num_digits_in_repeating_pattern, num_repetitions);

                    // if the smallest possible value with this pattern exceeds the range, break
                    if (pattern_min * generalised_repunit > range.end) break;

                    // we know that start ≤ pattern_val * R ≤ end
                    // therefore start / R ≤ pattern_val ≤ end / R
                    const lower = std.math.divCeil(u64, range.start, generalised_repunit) catch unreachable;
                    const upper = @divFloor(range.end, generalised_repunit);

                    const min_pattern_val = @max(pattern_min, lower);
                    const max_pattern_val = @min(pattern_max, upper);

                    // If empty intersection, skip
                    if (min_pattern_val > max_pattern_val) continue;

                    for (min_pattern_val..max_pattern_val + 1) |pattern_val| {
                        operation_count += 1;
                        const candidate_id = pattern_val * generalised_repunit;
                        const already_seen = seen.contains(candidate_id);
                        if (!already_seen) {
                            seen.putAssumeCapacity(candidate_id, undefined);
                            sum_of_invalid_ids += candidate_id;
                        }
                    }
                }
            }
        }
        return sum_of_invalid_ids;
    }
};

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    timer = std.time.Timer.start() catch unreachable;

    const start = timer.read();

    // TODO: this is probably a bad way to benchmark, maybe input data gets put in cache after the solution runs once? idk
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);

    const inputData = file_data[0 .. file_data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    operation_count = 0;
    const first_start_time = timer.read();
    const first_answer = try FirstSolution.solution(inputData);
    const first_end_time = timer.read();
    const operation_count_first = operation_count;

    operation_count = 0;
    const second_start_time = timer.read();
    const answer = try SmartSolution.solution(inputData, allocator);
    const second_end_time = timer.read();
    const operation_count_second = operation_count;

    var buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Elapsed time (file IO): {d} ns\n", .{after_io - start});

    try stdout.print("First solution answer: {d}\n", .{first_answer});
    try stdout.print("Elapsed time (first solution): {d} ns\n", .{first_end_time - first_start_time});
    try stdout.print("Total operations: {d}\n", .{operation_count_first});

    try stdout.print("Smart solution answer: {d}\n", .{answer});
    try stdout.print("Total operations: {d}\n", .{operation_count_second});
    try stdout.print("Elapsed time (smart solution): {d} ns\n", .{second_end_time - second_start_time});

    try stdout.flush();
}
