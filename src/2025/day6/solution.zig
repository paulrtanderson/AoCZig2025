const std = @import("std");
var timer: std.time.Timer = undefined;
const assert = std.debug.assert;

fn applyOperation(op_char: u8, before: u64, new: u64) u64 {
    return switch (op_char) {
        '*' => before * new,
        '+' => before + new,
        else => unreachable,
    };
}

fn getOperatorToken(inputdata: []const u8) struct { []const u8, usize } {
    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    var num_columns: usize = 0;
    while (it.next()) |token| {
        num_columns += 1;
        if (token[0] == '*' or token[0] == '+') {
            return .{ token, num_columns };
        }
    } else {
        unreachable;
    }
}

fn part1(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var initialised = false;

    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');

    const first_token = (it.peek() orelse unreachable);
    const token_length = first_token.len;
    var totals: std.ArrayList(u64) = try .initCapacity(gpa, token_length / 2 + 1);
    defer totals.deinit(gpa);

    const operator_token, const num_columns = getOperatorToken(inputdata);

    assert(num_columns > 0);
    assert(operator_token.len == token_length);

    it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    while (it.next()) |token| {
        assert(token.len == token_length);

        var operator_it = std.mem.tokenizeScalar(u8, operator_token, ' ');
        var line_it = std.mem.tokenizeScalar(u8, token, ' ');
        var i: usize = 0;
        while (line_it.next()) |number| : (i += 1) {
            const operator_string = operator_it.next() orelse {
                unreachable;
            };
            assert(operator_string.len == 1);

            const operator_char = operator_string[0];

            assert(operator_char == '*' or operator_char == '+');
            assert(number.len > 0);
            const char = number[0];
            if (std.ascii.isDigit(char)) {
                const num = try std.fmt.parseInt(u64, number, 10);
                if (!initialised) {
                    totals.appendAssumeCapacity(num);
                } else {
                    totals.items[i] = applyOperation(operator_char, totals.items[i], num);
                }
            } else {
                assert(char == '*' or char == '+');
                break;
            }
        }
        initialised = true;
    }
    var total: u64 = 0;
    assert(totals.items.len != 0);
    for (totals.items) |subtotal| {
        total += subtotal;
    }
    return total;
}

fn part2(inputdata: []const u8) u64 {
    const operator_token, const num_columns = getOperatorToken(inputdata);
    assert(num_columns > 0);

    var operator_it = std.mem.tokenizeScalar(u8, operator_token, ' ');
    const row_length = operator_token.len;

    var running_total: u64 = 0;
    var running_subtotal: u64 = 0;
    while (operator_it.peek()) |operator_string| : ({
        assert(running_subtotal > 0);
        running_total += running_subtotal;
        running_subtotal = 0;
    }) {
        const current_operator_index = operator_it.index;
        _ = operator_it.next();
        _ = operator_it.peek();

        assert(operator_string.len == 1);
        const operator_char = operator_string[0];
        assert(operator_char == '*' or operator_char == '+');

        var number_buffer: [20]u8 = undefined;

        assert(current_operator_index < operator_it.index);

        for (current_operator_index..operator_it.index) |offset| {
            var current_string_len: usize = 0;
            for (0..num_columns - 1) |row_index| {
                const buffer_index = offset + row_index * (row_length + 1); // +1 for newline
                const current_char = inputdata[buffer_index];
                if (current_char == ' ') continue;
                assert(std.ascii.isDigit(current_char));
                number_buffer[current_string_len] = current_char;
                current_string_len += 1;
            }
            if (current_string_len == 0) continue;

            const number_str = number_buffer[0..current_string_len];

            const number = std.fmt.parseInt(u16, number_str, 10) catch unreachable;
            if (running_subtotal == 0) {
                running_subtotal = number;
            } else {
                running_subtotal = applyOperation(operator_char, running_subtotal, number);
            }
        }
    }
    return running_total;
}

pub fn run(io: std.Io, allocator: std.mem.Allocator) !void {
    timer = std.time.Timer.start() catch unreachable;

    const start = timer.read();

    // TODO: this is probably a bad way to benchmark, maybe input data gets put in cache after the solution runs once? idk
    const filepath = "data/2025/day6/input.txt";
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);

    const inputData = file_data[0 .. file_data.len - 1]; // remove trailing newline
    const after_io = timer.read();

    const answer = try part1(allocator, inputData);
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

const embedded_input = @import("data").data_2025.day6.input;
const embedded_example = @import("data").data_2025.day6.example;

const part1_example_expected = 4277556;
const part2_example_expected = 3263827;

const part1_real_expected = 8108520669952;
const part2_real_expected = 11708563470209;

test "part1 example" {
    const result = try part1(std.testing.allocator, embedded_example);
    try std.testing.expectEqual(part1_example_expected, result);
}

test "part1 actual" {
    const result = try part1(std.testing.allocator, embedded_input);
    try std.testing.expectEqual(part1_real_expected, result);
}

test "part2 example" {
    const result = part2(embedded_example);
    try std.testing.expectEqual(part2_example_expected, result);
}

test "part2 actual" {
    const result = part2(embedded_input);
    try std.testing.expectEqual(part2_real_expected, result);
}
