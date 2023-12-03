const std = @import("std");
const expect = std.testing.expect;

const day = "day-01";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const simple2 = @embedFile("./inputs/" ++ day ++ "/simple2.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

fn tryDecodeDigit(s: []const u8, allow_strings: bool) ?u32 {
    if (std.ascii.isDigit(s[0])) {
        return std.fmt.charToDigit(s[0], 10) catch unreachable;
    }

    if (!allow_strings or s.len < 3) {
        // Every number needs at least 3 characters
        return null;
    }
    if (std.mem.startsWith(u8, s, "one")) {
        return 1;
    } else if (std.mem.startsWith(u8, s, "two")) {
        return 2;
    } else if (std.mem.startsWith(u8, s, "three")) {
        return 3;
    } else if (std.mem.startsWith(u8, s, "four")) {
        return 4;
    } else if (std.mem.startsWith(u8, s, "five")) {
        return 5;
    } else if (std.mem.startsWith(u8, s, "six")) {
        return 6;
    } else if (std.mem.startsWith(u8, s, "seven")) {
        return 7;
    } else if (std.mem.startsWith(u8, s, "eight")) {
        return 8;
    } else if (std.mem.startsWith(u8, s, "nine")) {
        return 9;
    }

    return null;
}

fn findCalibrationValue(line: []const u8, allow_digit_strings: bool) !u32 {
    var first_number_or_null: ?u32 = null;
    for (line, 0..) |_, idx| {
        const digit_or_null = tryDecodeDigit(line[idx..], allow_digit_strings);
        if (digit_or_null != null) {
            first_number_or_null = digit_or_null.?;
            break;
        }
    }
    if (first_number_or_null == null) {
        return error.NoDigitInLine;
    }
    const first_number = first_number_or_null.?;

    var last_number: u32 = undefined;
    var idx = line.len;
    while (idx >= 0) {
        idx -= 1;
        const digit_or_null = tryDecodeDigit(line[idx..], allow_digit_strings);
        if (digit_or_null != null) {
            last_number = digit_or_null.?;
            break;
        }
    }
    return first_number * 10 + last_number;
}

fn solve(input: [:0]const u8, allow_digit_strings: bool) !u64 {
    var lines_iterator = std.mem.splitScalar(u8, input, '\n');
    var sum: u64 = 0;
    while (lines_iterator.peek() != null) {
        const line = lines_iterator.next().?;
        if (line.len == 0) continue;
        const value = try findCalibrationValue(line, allow_digit_strings);
        sum += value;
    }
    return sum;
}

pub fn solveStar1(input: [:0]const u8) !u64 {
    return solve(input, false);
}

pub fn solveStar2(input: [:0]const u8) !u64 {
    return solve(input, true);
}

pub fn main() !void {
    const result1 = try solveStar1(full);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = try solveStar2(full);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const result = try solveStar1(simple);
    try expect(result == 142);
}

test "star 1 full" {
    const result = try solveStar1(full);
    try expect(result == 55971);
}

test "star 2 simple" {
    const result = try solveStar2(simple2);
    try expect(result == 281);
}

test "star 2 full" {
    const result = try solveStar2(full);
    try expect(result == 54719);
}
