const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-02";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

const CubeSet = struct {};

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, out_game_list: *ArrayList(CubeSet)) !void {
    _ = allocator;
    _ = out_game_list;

    const inputTrimmed = std.mem.trimRight(u8, input, &[_]u8{0});
    var lines_iterator = std.mem.splitScalar(u8, inputTrimmed, '\n');
    var next_line = lines_iterator.next();
    while (next_line != null) {
        const line = next_line.?;
        _ = line;
        next_line = lines_iterator.next();

        // TODO: Do something with line
    }
}

pub fn solveStar1(cube_sets: *ArrayList(CubeSet)) u64 {
    var sum: u64 = 0;
    for (cube_sets.items) |*cube_set| {
        _ = cube_set;

        sum += 1;
    }
    return sum;
}

pub fn solveStar2(cube_sets: *ArrayList(CubeSet)) u64 {
    var sum: u64 = 0;
    for (cube_sets.items) |*cube_set| {
        _ = cube_set;

        sum += 1;
    }
    return sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // We deallocate by finishing the program anyway :)
    const allocator = arena.allocator();
    var games = ArrayList(CubeSet).init(allocator);
    try parseInput(allocator, full, &games);

    const result1 = solveStar1(&games);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&games);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const allocator = std.testing.allocator;
    var cube_sets = ArrayList(CubeSet).init(allocator);
    defer {
        for (cube_sets.items) |game| game.draws.deinit();
        cube_sets.deinit();
    }
    try parseInput(allocator, simple, &cube_sets);

    const result = solveStar1(&cube_sets);
    try expect(result == 8);
}

test "star 1 full" {
    const allocator = std.testing.allocator;
    var cube_sets = ArrayList(CubeSet).init(allocator);
    try parseInput(allocator, full, &cube_sets);

    const result = solveStar1(&cube_sets);
    try expect(result == 2278);
}

test "star 2 simple" {
    const allocator = std.testing.allocator;
    var cube_sets = ArrayList(CubeSet).init(allocator);
    try parseInput(allocator, simple, &cube_sets);

    const result = solveStar2(&cube_sets);
    try expect(result == 2286);
}

test "star 2 full" {
    const allocator = std.testing.allocator;
    var cube_sets = ArrayList(CubeSet).init(allocator);
    try parseInput(allocator, full, &cube_sets);

    const result = solveStar2(&cube_sets);
    try expect(result == 67953);
}
