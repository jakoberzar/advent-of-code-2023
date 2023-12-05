const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-02";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

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
    var games = ArrayList(CubeSet).init(ga);
    try parseInput(ga, full, &games);

    const result1 = solveStar1(&games);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&games);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var cube_sets = ArrayList(CubeSet).init(ga);
    try parseInput(ga, simple, &cube_sets);

    const result1 = solveStar1(&cube_sets);
    try expect(result1 == 8);
    // const result2 = solveStar2(&cube_sets);
    // try expect(result2 == 2286);
}

test "full" {
    var cube_sets = ArrayList(CubeSet).init(ga);
    try parseInput(ga, full, &cube_sets);

    const result1 = solveStar1(&cube_sets);
    try expect(result1 == 2278);
    // const result2 = solveStar2(&cube_sets);
    // try expect(result2 == 67953);
}
