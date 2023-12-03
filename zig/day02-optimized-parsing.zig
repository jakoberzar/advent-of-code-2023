const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;

const utils = @import("utils.zig");

const day = "day-02";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

const CubeCount = u32;
const CubeSet = struct {
    red: CubeCount = 0,
    green: CubeCount = 0,
    blue: CubeCount = 0,
};

const max_draw = CubeSet{
    .red = 12,
    .green = 13,
    .blue = 14,
};

fn parseDraw(draw_text: []const u8) !CubeSet {
    var char_idx: usize = 0;
    var draw = CubeSet{};
    while (char_idx < draw_text.len) {
        // Skip possible ", "
        while (char_idx < draw_text.len and !isDigit(draw_text[char_idx])) : (char_idx += 1) {}

        const cube_string = draw_text[char_idx..];
        const number_parsed = try utils.parseNumberAtStart(CubeCount, cube_string);
        char_idx += number_parsed.consumed;
        char_idx += 1; // Skip space after number
        switch (draw_text[char_idx]) {
            'r' => {
                draw.red = number_parsed.value;
                char_idx += 3; // Skip "red"
            },
            'g' => {
                draw.green = number_parsed.value;
                char_idx += 5; // Skip "green"
            },
            'b' => {
                draw.blue = number_parsed.value;
                char_idx += 4; // Skip "blue"
            },
            else => return error.InvalidCubeType,
        }
    }
    return draw;
}

test "parse draw" {
    const draw = try parseDraw("8 green, 6 blue, 20 red");
    try expect(draw.green == 8);
    try expect(draw.blue == 6);
    try expect(draw.red == 20);

    const draw2 = try parseDraw("13 red");
    try expect(draw2.red == 13);
}

fn isGamePossible(line: []const u8) !bool {
    var char_idx: usize = 0;
    while (char_idx < line.len and line[char_idx] != ':') : (char_idx += 1) {}
    char_idx += 1; // Skip space
    char_idx += 1; // Set to field after space
    std.debug.assert(char_idx < line.len);
    var split_draw = std.mem.splitScalar(u8, line[char_idx..], ';');
    var draw_idx: usize = 1;
    while (split_draw.peek() != null) {
        var draw_string = split_draw.next().?;
        if (draw_idx > 1) {
            draw_string = draw_string[1..]; // Skip space after separator
        }
        const draw = try parseDraw(draw_string);
        if (draw.red > max_draw.red or draw.green > max_draw.green or draw.blue > max_draw.blue) {
            return false;
        }
        draw_idx += 1;
    }
    return true;
}

pub fn solveStar1(input: [:0]const u8) !u64 {
    var lines_iterator = std.mem.splitScalar(u8, input, '\n');
    var sum: u64 = 0;
    var game_id: CubeCount = 1;
    while (lines_iterator.peek() != null) {
        const line = lines_iterator.next().?;
        if (line.len == 0) continue;
        const is_possible = try isGamePossible(line);
        if (is_possible) {
            sum += game_id;
        }
        game_id += 1;
    }
    return sum;
}

fn minCubesNeeded(line: []const u8) !CubeSet {
    var char_idx: usize = 0;
    while (char_idx < line.len and line[char_idx] != ':') : (char_idx += 1) {}
    char_idx += 1; // Skip space
    char_idx += 1; // Set to field after space
    std.debug.assert(char_idx < line.len);
    var split_draw = std.mem.splitScalar(u8, line[char_idx..], ';');
    var draw_idx: usize = 1;
    var min_cubes = CubeSet{};
    while (split_draw.peek() != null) {
        var draw_string = split_draw.next().?;
        if (draw_idx > 1) {
            draw_string = draw_string[1..];
        }
        const draw = try parseDraw(draw_string);
        if (draw.red > min_cubes.red) min_cubes.red = draw.red;
        if (draw.green > min_cubes.green) min_cubes.green = draw.green;
        if (draw.blue > min_cubes.blue) min_cubes.blue = draw.blue;
        draw_idx += 1;
    }
    return min_cubes;
}

fn getCubeSetPower(cube_set: CubeSet) u32 {
    return @as(u32, cube_set.red) * @as(u32, cube_set.green) * @as(u32, cube_set.blue);
}

test "cube set power" {
    try expect(getCubeSetPower(CubeSet{ .red = 20, .green = 13, .blue = 6 }) == 1560);
}

pub fn solveStar2(input: [:0]const u8) !u64 {
    var lines_iterator = std.mem.splitScalar(u8, input, '\n');
    var sum: u64 = 0;
    while (lines_iterator.peek() != null) {
        const line = lines_iterator.next().?;
        if (line.len == 0) continue;
        const min_cubes_needed = try minCubesNeeded(line);
        const cubes_power = getCubeSetPower(min_cubes_needed);
        sum += cubes_power;
    }
    return sum;
}

pub fn main() !void {
    const result1 = try solveStar1(full);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = try solveStar2(full);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const result = try solveStar1(simple);
    try expect(result == 8);
}

test "star 1 full" {
    const result = try solveStar1(full);
    try expect(result == 2278);
}

test "star 2 simple" {
    const result = try solveStar2(simple);
    try expect(result == 2286);
}

test "star 2 full" {
    const result = try solveStar2(full);
    try expect(result == 67953);
}
