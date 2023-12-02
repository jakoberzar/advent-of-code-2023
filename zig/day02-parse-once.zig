const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const day = "day-02";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

const CubeCount = u32;
const CubeSet = struct {
    red: CubeCount = 0,
    green: CubeCount = 0,
    blue: CubeCount = 0,
};
const Game = struct {
    id: u32,
    draws: ArrayList(CubeSet),
    fn print(self: *Game) void {
        std.debug.print("This is game {}, draws: ", .{self.id});
        for (self.draws.items) |*draw| {
            std.debug.print("{}R{}G{}B;", .{ draw.red, draw.green, draw.blue });
        }
        std.debug.print("\n", .{});
    }
};

fn ParseResult(comptime T: type) type {
    return struct {
        value: T,
        consumed: usize,
    };
}

const max_draw = CubeSet{
    .red = 12,
    .green = 13,
    .blue = 14,
};

fn charToDigit(char: u8) u8 {
    return char - '0';
}

fn parseNumberAtStart(s: []const u8) !ParseResult(CubeCount) {
    if (s.len == 0) return error.NoInputWhileParsingNumber;
    if (!isDigit(s[0])) return error.NoNumberWhileParsingNumber;
    var parsed: CubeCount = charToDigit(s[0]);
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
    const parsed = try parseNumberAtStart("25 red");
    try expect(parsed.value == 25);
    try expect(parsed.consumed == 2);
}

fn parseDraw(draw_text: []const u8) !ParseResult(CubeSet) {
    var char_idx: usize = 0;
    var draw = CubeSet{};
    while (char_idx < draw_text.len and draw_text[char_idx] != ';') {
        // Skip possible ", "
        while (char_idx < draw_text.len and !isDigit(draw_text[char_idx])) : (char_idx += 1) {}

        const cube_string = draw_text[char_idx..];
        const number_parsed = try parseNumberAtStart(cube_string);
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
    return .{ .value = draw, .consumed = char_idx };
}

test "parse draw" {
    const draw = try parseDraw("8 green, 6 blue, 20 red");
    try expect(draw.value.green == 8);
    try expect(draw.value.blue == 6);
    try expect(draw.value.red == 20);
    try expect(draw.consumed == 23);

    const draw2 = try parseDraw("13 red; 5 blue");
    try expect(draw2.value.red == 13);
    try expect(draw2.consumed == 6);
}

fn parseGameDraws(game_line: []const u8, out_draws: *ArrayList(CubeSet)) !void {
    var char_idx: usize = 0;
    while (char_idx < game_line.len and game_line[char_idx] != ':') : (char_idx += 1) {}
    char_idx += 2; // Skip space and field after space
    var draw_idx: usize = 1;
    while (char_idx < game_line.len) {
        const parsed = try parseDraw(game_line[char_idx..]);
        try out_draws.append(parsed.value);
        char_idx += parsed.consumed;
        char_idx += 2; // Skip possible semicolon and space

        draw_idx += 1;
    }
}

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, out_game_list: *ArrayList(Game)) !void {
    var lines_iterator = std.mem.splitScalar(u8, input, '\n');
    var next_line = lines_iterator.next();
    var game_id: u32 = 1;
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();
        if (line.len == 0) continue;

        const new_game = try out_game_list.addOne();
        new_game.id = game_id;
        new_game.draws = ArrayList(CubeSet).init(allocator);
        try parseGameDraws(line, &new_game.draws);

        game_id += 1;
    }
}

fn isGamePossible(game: *Game) bool {
    for (game.draws.items) |*draw| {
        if (draw.red > max_draw.red or draw.green > max_draw.green or draw.blue > max_draw.blue) {
            return false;
        }
    }
    return true;
}

pub fn solveStar1(games: *ArrayList(Game)) u64 {
    var sum: u64 = 0;
    for (games.items) |*game| {
        const is_possible = isGamePossible(game);
        if (is_possible) {
            sum += game.id;
        }
    }
    return sum;
}

fn minCubesNeeded(game: *Game) CubeSet {
    var min_cubes = CubeSet{};
    for (game.draws.items) |*draw| {
        if (draw.red > min_cubes.red) min_cubes.red = draw.red;
        if (draw.green > min_cubes.green) min_cubes.green = draw.green;
        if (draw.blue > min_cubes.blue) min_cubes.blue = draw.blue;
    }
    return min_cubes;
}

fn getCubeSetPower(cube_set: CubeSet) u32 {
    return @as(u32, cube_set.red) * @as(u32, cube_set.green) * @as(u32, cube_set.blue);
}

test "cube set power" {
    try expect(getCubeSetPower(CubeSet{ .red = 20, .green = 13, .blue = 6 }) == 1560);
}

pub fn solveStar2(games: *ArrayList(Game)) u64 {
    var sum: u64 = 0;
    for (games.items) |*game| {
        const min_cubes_needed = minCubesNeeded(game);
        const cubes_power = getCubeSetPower(min_cubes_needed);
        sum += cubes_power;
    }
    return sum;
}

// var heap_buffer: [1_000_000]u8 = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit(); // We deallocate by finishing the program anyway :)
    const allocator = arena.allocator();
    // var fba = std.heap.FixedBufferAllocator.init(&heap_buffer);
    // const allocator = fba.allocator();
    var games = ArrayList(Game).init(allocator);
    try parseInput(allocator, full, &games);

    const result1 = solveStar1(&games);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&games);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const allocator = std.testing.allocator;
    var games = ArrayList(Game).init(allocator);
    defer {
        for (games.items) |game| game.draws.deinit();
        games.deinit();
    }
    try parseInput(allocator, simple, &games);

    const result = solveStar1(&games);
    try expect(result == 8);
}

test "star 1 full" {
    const allocator = std.testing.allocator;
    var games = ArrayList(Game).init(allocator);
    defer {
        for (games.items) |game| game.draws.deinit();
        games.deinit();
    }
    try parseInput(allocator, full, &games);

    const result = solveStar1(&games);
    try expect(result == 2278);
}

test "star 2 simple" {
    const allocator = std.testing.allocator;
    var games = ArrayList(Game).init(allocator);
    defer {
        for (games.items) |game| game.draws.deinit();
        games.deinit();
    }
    try parseInput(allocator, simple, &games);

    const result = solveStar2(&games);
    try expect(result == 2286);
}

test "star 2 full" {
    const allocator = std.testing.allocator;
    var games = ArrayList(Game).init(allocator);
    defer {
        for (games.items) |game| game.draws.deinit();
        games.deinit();
    }
    try parseInput(allocator, full, &games);

    const result = solveStar2(&games);
    try expect(result == 67953);
}
