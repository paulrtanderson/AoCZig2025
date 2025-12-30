const std = @import("std");
const ReadFileError = std.Io.Dir.ReadFileError;
const Allocator = std.mem.Allocator;
const StatError = std.Io.File.StatError;
pub const ReadAllocError = Allocator.Error || StatError || ReadFileError;

const FileData = struct {
    buffer: []u8, // caller must free this
    data: []u8, // valid bytes inside buffer
};

pub fn readFileAlloc(gpa: Allocator, path: []const u8, io: std.Io) ReadAllocError!FileData {
    const dir = std.Io.Dir.cwd();

    var file = try dir.openFile(io, path, .{});
    defer file.close(io);

    const file_size = (try file.stat(io)).size;

    const buffer = try gpa.alloc(u8, @intCast(file_size));
    errdefer gpa.free(buffer);

    var reader = file.reader(io, &.{});
    const n = reader.interface.readSliceShort(buffer) catch |err| switch (err) {
        error.ReadFailed => return reader.err.?,
    };

    return FileData{
        .buffer = buffer,
        .data = buffer[0..n],
    };
}

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
