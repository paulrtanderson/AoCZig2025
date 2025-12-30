const std = @import("std");
var timer: std.time.Timer = undefined;
const filepath = "src/day6/input.txt";
const utils = @import("utils");
const readFileAlloc = utils.readFileAlloc;
const assert = std.debug.assert;

const operation = enum { add, sub, mul, div };

fn applyOperation(op_char: u8, before: u64, new: u64) u64 {
    return switch (op_char) {
        '*' => before * new,
        '+' => before + new,
        else => unreachable,
    };
}

pub fn part1(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var initialised = false;

    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    var operator_token: []const u8 = undefined;

    const token_length = it.peek().?.len;
    var totals: std.ArrayList(u64) = try .initCapacity(gpa, token_length / 2 + 1);
    defer totals.deinit(gpa);

    var found = false;
    while (it.next()) |token| {
        if (token[0] == '*' or token[0] == '+') {
            operator_token = token;
            found = true;
            break;
        }
    }

    assert(found);

    it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    while (it.next()) |token| {
        var operator_it = std.mem.tokenizeScalar(u8, operator_token, ' ');
        var line_it = std.mem.tokenizeScalar(u8, token, ' ');
        var i: usize = 0;
        while (line_it.next()) |number| : (i += 1) {
            const operator_string = operator_it.next() orelse unreachable;
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

fn part2(gpa: std.mem.Allocator, inputdata: []const u8) !u64 {
    var initialised = false;
    initialised = false;

    var it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    var operator_token: []const u8 = undefined;

    const token_length = it.peek().?.len;
    var totals: std.ArrayList(u64) = try .initCapacity(gpa, token_length / 2 + 1);
    defer totals.deinit(gpa);

    var found = false;
    while (it.next()) |token| {
        if (token[0] == '*' or token[0] == '+') {
            operator_token = token;
            found = true;
            break;
        }
    }

    assert(found);

    it = std.mem.tokenizeScalar(u8, inputdata, '\n');
    while (it.next()) |token| {
        _ = token;
    }
    return 0;
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

    const answer = try part1(allocator, inputData);
    const end = timer.read();

    const inputDatatest =
        \\3-5
        \\5-14
        \\14-14
        \\19-20
        \\
        \\
    ;
    _ = inputDatatest;

    const start2 = timer.read();
    const answer2 = try part2(allocator, inputData);
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
