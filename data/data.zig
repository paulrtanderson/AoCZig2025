const std = @import("std");

fn DayData(comptime path_prefix: []const u8) type {
    const input_path = path_prefix ++ "/input.txt";
    const example_path = path_prefix ++ "/example.txt";

    return struct {
        pub const input = @embedFile(input_path);
        pub const example = @embedFile(example_path);
        pub const input_path_str = "data/" ++ input_path;
        pub const example_path_str = "data/" ++ example_path;
    };
}

pub const data_2025 = .{
    .day1 = DayData("2025/day1"),
    .day2 = DayData("2025/day2"),
    .day3 = DayData("2025/day3"),
    .day4 = DayData("2025/day4"),
    .day5 = DayData("2025/day5"),
    .day6 = DayData("2025/day6"),
    .day7 = DayData("2025/day7"),
    .day8 = DayData("2025/day8"),
};
