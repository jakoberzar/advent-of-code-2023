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

fn charToDigit(char: u8) u8 {
    return char - '0';
}
