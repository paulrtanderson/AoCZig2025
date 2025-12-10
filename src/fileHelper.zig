const std = @import("std");
const ReadFileError = std.Io.Dir.ReadFileError;
const Allocator = std.mem.Allocator;
const StatError = std.fs.File.StatError;
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
