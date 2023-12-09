const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;

pub fn ParseResult(comptime T: type) type {
    return struct {
        value: T,
        consumed: usize,
    };
}

pub fn parseNumberAtStart(comptime T: type, s: []const u8) !ParseResult(T) {
    if (s.len == 0) return error.NoInputWhileParsingNumber;
    if (!isDigit(s[0])) return error.NoNumberWhileParsingNumber;
    var parsed: T = charToDigit(s[0]);
    var idx: usize = 1;
    while (idx < s.len and isDigit(s[idx])) : (idx += 1) {
        parsed *= 10;
        parsed += charToDigit(s[idx]);
    }
    return .{
        .value = parsed,
        .consumed = idx,
    };
}

test "parse number at start" {
    const parsed = try parseNumberAtStart(u32, "25 red");
    try expect(parsed.value == 25);
    try expect(parsed.consumed == 2);
}

test "parse number at start grid" {
    const parsed = try parseNumberAtStart(u32, "467...");
    try expect(parsed.value == 467);
    try expect(parsed.consumed == 3);
}

// Returns the lowest common multiple (lcm) of two unsigned numbers.
pub fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .Int => |int| std.debug.assert(int.signedness == .unsigned),
        .ComptimeInt => {
            std.debug.assert(a >= 0);
            std.debug.assert(b >= 0);
        },
        else => unreachable,
    };
    return a * b / std.math.gcd(a, b);
}

test "lcm" {
    try expect(lcm(15, 20) == 60);
}

fn charToDigit(char: u8) u8 {
    return char - '0';
}
