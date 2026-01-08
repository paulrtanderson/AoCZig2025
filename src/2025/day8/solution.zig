const std = @import("std");
const mem = std.mem;
const math = std.math;
const sort = std.sort;
const assert = std.debug.assert;
const data = @import("data").data_2025.day8;
const Point3 = struct {
    pub const Scalar = i32;

    x: Scalar,
    y: Scalar,
    z: Scalar,

    pub fn distanceTo(self: Point3, other: Point3) f64 {
        const dx = @as(f64, @floatFromInt(self.x - other.x));
        const dy = @as(f64, @floatFromInt(self.y - other.y));
        const dz = @as(f64, @floatFromInt(self.z - other.z));

        return std.math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn squaredDistance(a: Point3, b: Point3) f64 {
        const dx: f64 = @floatFromInt(a.x - b.x);
        const dy: f64 = @floatFromInt(a.y - b.y);
        const dz: f64 = @floatFromInt(a.z - b.z);

        return dx * dx + dy * dy + dz * dz;
    }
};

fn parsePoint(line: []const u8) !Point3 {
    var it = std.mem.tokenizeScalar(u8, line, ',');
    var coords: [3]Point3.Scalar = undefined;
    var i: usize = 0;
    while (it.next()) |token| : (i += 1) {
        assert(i < 3);
        const coord = try std.fmt.parseInt(Point3.Scalar, token, 10);
        coords[i] = coord;
    }
    return Point3{
        .x = coords[0],
        .y = coords[1],
        .z = coords[2],
    };
}

fn readAllPoints(allocator: std.mem.Allocator, r: *std.Io.Reader) ![]Point3 {
    var coord_list = try std.ArrayList(Point3).initCapacity(allocator, 1000);
    errdefer coord_list.deinit(allocator);
    while (try r.takeDelimiter('\n')) |line| {
        try coord_list.append(allocator, try parsePoint(line));
    }
    return coord_list.toOwnedSlice(allocator);
}

fn part1(allocator: std.mem.Allocator, r: *std.Io.Reader, num_connections: usize) !u64 {
    var coord_list = try readAllPoints(allocator, r);
    defer allocator.free(coord_list);
    // upper triangular distance matrix

    const n = coord_list.len;
    const matrix_size = n * n;

    var distances_matrix = try allocator.alloc(f64, matrix_size);
    defer allocator.free(distances_matrix);

    @memset(distances_matrix, math.floatMax(f64));

    var index: usize = 0;
    for (coord_list, 0..) |point_a, i| {
        for (coord_list, 0..) |point_b, j| {
            defer index += 1;
            if (i >= j) continue;
            const dist = point_a.distanceTo(point_b);
            distances_matrix[index] = dist;
        }
    }

    const sorted_distances_indexes = try allocator.alloc(usize, num_connections);
    defer allocator.free(sorted_distances_indexes);

    const workspace = try allocator.alloc(usize, matrix_size);
    defer allocator.free(workspace);
    getLowestKIndices(f64, distances_matrix, sorted_distances_indexes, workspace);

    //printClosestPoints(coord_list, sorted_distances_indexes, n);

    return try getSubGraphLengths(allocator, sorted_distances_indexes, n, coord_list);
}

fn findParent(
    parent_map: *std.AutoHashMap(usize, usize),
    node: usize,
) usize {
    const entry = parent_map.getOrPutAssumeCapacity(node);
    if (!entry.found_existing) {
        entry.value_ptr.* = node;
        return node;
    }
    var current = node;
    while (true) {
        const parent_ptr = parent_map.getPtr(current).?;
        if (parent_ptr.* == current) break;
        const grandparent = parent_map.get(parent_ptr.*).?;
        parent_ptr.* = grandparent;
        current = grandparent;
    }
    return current;
}

fn getSubGraphLengths(allocator: std.mem.Allocator, connection_indices: []usize, n: usize, coords: []Point3) !u64 {
    // Upper bound: at most 2 * E unique points are involved
    const max_points = 2 * connection_indices.len;

    var parent = std.AutoHashMap(usize, usize).init(allocator);
    defer parent.deinit();
    try parent.ensureTotalCapacity(@intCast(max_points));

    var size = std.AutoHashMap(usize, usize).init(allocator);
    defer size.deinit();
    try size.ensureTotalCapacity(@intCast(max_points));

    for (connection_indices) |conn_index| {
        const row, const col = indexToRowCol(conn_index, n);
        const rootA = findParent(&parent, row);
        const rootB = findParent(&parent, col);

        if (rootA == rootB) continue;

        const sizeA = size.get(rootA) orelse 1;
        const sizeB = size.get(rootB) orelse 1;

        if (sizeA < sizeB) {
            parent.putAssumeCapacity(rootA, rootB);
            size.putAssumeCapacity(rootB, sizeA + sizeB);
            _ = size.remove(rootA);
        } else {
            parent.putAssumeCapacity(rootB, rootA);
            size.putAssumeCapacity(rootA, sizeA + sizeB);
            _ = size.remove(rootB);
        }
        if (sizeA + sizeB == coords.len) {
            std.debug.print("All points connected!\n", .{});
            std.debug.print("Final connection between {d} and {d}\n", .{ row, col });
            std.debug.print("Which are points: ", .{});
            printPoint3(coords[row]);
            std.debug.print(" and ", .{});
            printPoint3(coords[col]);
            std.debug.print("\n", .{});
            break;
        }
    }
    var three_largest = [3]u64{ 0, 0, 0 };

    var it = size.iterator();
    while (it.next()) |entry| {
        //std.debug.print("Subgraph with size: {d}\n", .{entry.value_ptr.*});
        const subgraph_size = entry.value_ptr.*;

        if (subgraph_size > three_largest[0]) {
            three_largest[2] = three_largest[1];
            three_largest[1] = three_largest[0];
            three_largest[0] = subgraph_size;
        } else if (subgraph_size > three_largest[1]) {
            three_largest[2] = three_largest[1];
            three_largest[1] = subgraph_size;
        } else if (subgraph_size > three_largest[2]) {
            three_largest[2] = subgraph_size;
        }
    }

    const connected_product = @max(three_largest[0], 1) * @max(three_largest[1], 1) * @max(three_largest[2], 1);

    return connected_product;
}

fn printClosestPoints(points_list: []Point3, points_indexes: []usize, n: usize) void {
    for (points_indexes) |point_index| {
        const row, const col = indexToRowCol(point_index, n);
        const p1 = points_list[row];
        const p2 = points_list[col];
        std.debug.print("Closest points: ", .{});
        printPoint3(p1);
        std.debug.print(" and ", .{});
        printPoint3(p2);
        std.debug.print("\n", .{});
    }
}

fn printPoint3(p: Point3) void {
    std.debug.print("({d}, {d}, {d})", .{ p.x, p.y, p.z });
}

fn indexToRowCol(index: usize, row_length: usize) struct { usize, usize } {
    const row = index / row_length;
    const col = index % row_length;
    return .{ row, col };
}

/// Returns the indices of the k smallest elements, sorted ascending.
pub fn getLowestKIndices(
    comptime T: type,
    buffer: []const T,
    k_indices: []usize, // Should be length k
    all_indices: []usize, // Workspace, same length as buffer
) void {
    for (all_indices, 0..) |*item, i| item.* = i;

    const Context = struct {
        buf: []const T,
        indices: []usize,
        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return ctx.buf[ctx.indices[a]] < ctx.buf[ctx.indices[b]];
        }
        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            mem.swap(usize, &ctx.indices[a], &ctx.indices[b]);
        }
    };

    const ctx = Context{ .buf = buffer, .indices = all_indices };

    nthElementContext(k_indices.len, 0, all_indices.len, ctx);

    sort.heap(usize, all_indices[0..k_indices.len], ctx, (struct {
        fn lt(c: Context, a: usize, b: usize) bool {
            return c.buf[a] < c.buf[b];
        }
    }).lt);

    @memcpy(k_indices, all_indices[0..k_indices.len]);
}

// shamelessly stolen and adapted from
// https://github.com/ziglang/zig/issues/9890#issuecomment-3059720017
fn nthElementContext(n: usize, a: usize, b: usize, context: anytype) void {
    var left = a;
    var right = b;
    var depth_limit = if (right > left) math.log2_int(usize, right - left) * 2 else 0;

    while (right - left > 8) {
        if (depth_limit == 0) {
            heapSelectContext(n - left, left, right, context);
            return;
        }
        depth_limit -= 1;

        var pivot = left + (right - left) / 2;
        // Basic Median-of-3 pivot selection
        const mid = left + (right - left) / 2;
        if (context.lessThan(mid, left)) context.swap(left, mid);
        if (context.lessThan(right - 1, mid)) context.swap(mid, right - 1);
        if (context.lessThan(mid, left)) context.swap(left, mid);
        pivot = mid;

        partition(left, right, &pivot, context);

        if (pivot == n) return;
        if (pivot > n) {
            right = pivot;
        } else {
            left = pivot + 1;
        }
    }
    sort.insertionContext(left, right, context);
}

// shamelessly stolen and adapted from
// https://github.com/ziglang/zig/issues/9890#issuecomment-3059720017
pub fn heapSelectContext(n: usize, a: usize, b: usize, context: anytype) void {
    const len = b - a;
    const n_largest = len - n;
    var i = a + len / 2;
    while (i > a) {
        i -= 1;
        siftDown(a, i, b, context);
    }
    var heap_end = b;
    var count: usize = 0;
    while (count < n_largest - 1) : (count += 1) {
        heap_end -= 1;
        context.swap(a, heap_end);
        siftDown(a, a, heap_end, context);
    }
    context.swap(a, a + n);
}

// taken from std.sort.pdq because it's a non pub function :(
fn partition(a: usize, b: usize, pivot: *usize, context: anytype) void {
    context.swap(a, pivot.*);
    var i = a + 1;
    var j = b - 1;
    while (true) {
        while (i <= j and context.lessThan(i, a)) i += 1;
        while (i <= j and !context.lessThan(j, a)) j -= 1;
        if (i > j) break;
        context.swap(i, j);
        i += 1;
        j -= 1;
    }
    context.swap(j, a);
    pivot.* = j;
}

// taken from std.sort because it's a non pub function :(
fn siftDown(a: usize, target: usize, b: usize, context: anytype) void {
    var cur = target;
    while (true) {
        var child = (math.mul(usize, cur - a, 2) catch break) + a + 1;
        if (!(child < b)) break;
        const next_child = child + 1;
        if (next_child < b and context.lessThan(child, next_child)) {
            child = next_child;
        }
        if (context.lessThan(child, cur)) break;
        context.swap(child, cur);
        cur = child;
    }
}

fn part2(gpa: std.mem.Allocator, r: *std.Io.Reader) !u64 {
    // We need to find a minimum bottle neck spanning tree
    // since this is a complete graph, finding the MST via Prim's algorithm is just as efficient as Camerini's algorithm for MBSTs
    // in fact prims algorithm is optimal for complete graphs

    // allocated vertices
    const coords = try readAllPoints(gpa, r);
    defer gpa.free(coords);
    const n = coords.len;

    if (n <= 1) return 0;

    var distances_to_tree = try gpa.alloc(f64, n);
    defer gpa.free(distances_to_tree);
    var sources_x_value = try gpa.alloc(Point3.Scalar, n);
    defer gpa.free(sources_x_value);
    @memset(distances_to_tree, math.floatMax(f64));
    @memset(sources_x_value, coords[0].x);

    var max_edge: f64 = 0.0;
    var bottleneck_a_x: Point3.Scalar = 0;
    var bottleneck_b_x: Point3.Scalar = 0;

    // prim's algorithm
    distances_to_tree[0] = 0.0;
    for (1..n) |i| {
        const last_point = coords[i - 1];
        var best_distance: f64 = math.floatMax(f64);
        var best_distance_index: usize = 0;
        for (i..n) |j| {
            const dist = Point3.squaredDistance(last_point, coords[j]);
            if (dist < distances_to_tree[j]) {
                distances_to_tree[j] = dist;
                sources_x_value[j] = last_point.x;
            }
            const dist_to_tree = distances_to_tree[j];
            if (dist_to_tree < best_distance) {
                best_distance = dist_to_tree;
                best_distance_index = j;
            }
        }

        if (best_distance > max_edge) {
            max_edge = best_distance;
            bottleneck_a_x = sources_x_value[best_distance_index];
            bottleneck_b_x = coords[best_distance_index].x;
        }
        std.mem.swap(Point3, &coords[best_distance_index], &coords[i]);
        std.mem.swap(f64, &distances_to_tree[best_distance_index], &distances_to_tree[i]);
        std.mem.swap(Point3.Scalar, &sources_x_value[best_distance_index], &sources_x_value[i]);
    }
    const product_of_xs = bottleneck_a_x * bottleneck_b_x;
    return @intCast(product_of_xs);
}

fn timePart1(context: []const u8, allocator: std.mem.Allocator) !u64 {
    var reader: std.Io.Reader = .fixed(context);
    var timer: std.time.Timer = try .start();
    const res = try part1(allocator, &reader, 1000);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

fn timePart2(context: []const u8, allocator: std.mem.Allocator) !u64 {
    var reader: std.Io.Reader = .fixed(context);
    var timer: std.time.Timer = try .start();
    const res = try part2(allocator, &reader);
    const elapsed = timer.read();
    std.mem.doNotOptimizeAway(res);
    return elapsed;
}

const utils = @import("utils");
pub fn benchmark(allocator: std.mem.Allocator, backing_allocator: std.mem.Allocator, io: std.Io, filepath: []const u8, stdout: *std.Io.Writer, runs: u32) !void {
    const dir = std.Io.Dir.cwd();
    const file_data = try dir.readFileAlloc(io, filepath, allocator, .unlimited);
    defer allocator.free(file_data);
    const input_data = file_data[0 .. file_data.len - 1];

    try utils.benchmarkGeneric(allocator, backing_allocator, input_data, timePart1, "Part 1", stdout, runs);
    try stdout.flush();
    try utils.benchmarkGeneric(allocator, backing_allocator, input_data, timePart2, "Part 2", stdout, runs);
    try stdout.flush();
    std.debug.print("finished the benchmark\n", .{});
}

pub fn run(io: std.Io, allocator: std.mem.Allocator, out: *std.Io.Writer, filepath: []const u8, connections: usize) !void {
    const dir = std.Io.Dir.cwd();
    const file = try dir.openFile(io, filepath, .{});
    defer file.close(io);
    var file_buffer: [1000]u8 = undefined;
    var file_reader = file.reader(io, &file_buffer);
    const reader = &file_reader.interface;
    const answer1 = try part1(allocator, reader, connections);

    try file_reader.seekTo(0);
    const answer2 = try part2(allocator, reader);

    try out.print("Answer part 1: {d}\n", .{answer1});
    try out.print("Answer part 2: {d}\n", .{answer2});
    try out.flush();
}

const testing = std.testing;
const data_day_8 = @import("data").data_2025.day8;
const embedded_input = data_day_8.input;
const embedded_example = data_day_8.example;

const part1_input_embedded = Part1Input{
    .input = embedded_input,
    .connections = 1000,
};

const part1_example_input = Part1Input{
    .input = embedded_example,
    .connections = 10,
};

const part1_example_expected = 40;
const part2_example_expected = 25272;

const part1_real_expected = 163548;
const part2_real_expected = 772452514;

const Part1Input = struct {
    input: []const u8,
    connections: usize,
};

fn checkPart1(input: Part1Input, expected: usize) !void {
    const input_data = input.input;
    const connections = input.connections;
    var reader: std.Io.Reader = .fixed(input_data);
    const result = try part1(testing.allocator, &reader, connections);
    try testing.expectEqual(expected, result);
}

test "day 8 part 1" {
    try checkPart1(part1_example_input, part1_example_expected);
    try checkPart1(part1_input_embedded, part1_real_expected);
}

fn checkPart2(input: []const u8, expected: usize) !void {
    var reader: std.Io.Reader = .fixed(input);
    const result = try part2(testing.allocator, &reader);
    try testing.expectEqual(expected, result);
}

test "day 8 part 2" {
    // Currently not implemented
    try checkPart2(embedded_example, part2_example_expected);
    try checkPart2(embedded_input, part2_real_expected);
}

fn checkRun(input: Part1Input, expected_part1: u64, expected_part2: u64) !void {
    const input_path = input.input;
    const allocator = testing.allocator;
    var allocating_writer: std.Io.Writer.Allocating = .init(allocator);
    defer allocating_writer.deinit();
    const writer = &allocating_writer.writer;
    try run(std.testing.io, allocator, writer, input_path, input.connections);
    const output = try allocating_writer.toOwnedSlice();
    defer allocator.free(output);

    const part1_str = try std.fmt.allocPrint(allocator, "{d}", .{expected_part1});
    defer allocator.free(part1_str);
    const part2_str = try std.fmt.allocPrint(allocator, "{d}", .{expected_part2});
    defer allocator.free(part2_str);

    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, part1_str));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, part2_str));
}

const run_input_example = Part1Input{
    .input = data_day_8.example_path_str,
    .connections = 10,
};
const run_input_real = Part1Input{
    .input = data_day_8.input_path_str,
    .connections = 1000,
};

test "day 8 run" {
    try checkRun(run_input_example, part1_example_expected, part2_example_expected);
    try checkRun(run_input_real, part1_real_expected, part2_real_expected);
}
