const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-11";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();
const grid_size_simple = std.mem.indexOfScalar(u8, simple, '\n').?;
const grid_size_full = std.mem.indexOfScalar(u8, full, '\n').?;
const max_grid_size = @max(grid_size_full, grid_size_simple);
const Grid = [max_grid_size][max_grid_size]u8;
var stored_grid: Grid = [_][max_grid_size]u8{[_]u8{0} ** max_grid_size} ** max_grid_size;

const CoordUnit = u64;
const Coords = struct { row: CoordUnit, col: CoordUnit };
const Galaxy = Coords;

fn parseInput(input: [:0]const u8, out_grid: *Grid, out_galaxy_list: *ArrayList(Galaxy)) !void {
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input_trimmed, '\n');
    var next_line = lines_iterator.next();
    var row: CoordUnit = 0;
    while (next_line != null) : (row += 1) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        std.mem.copyForwards(u8, &out_grid[row], line);
        var col: CoordUnit = 0;
        while (col < line.len) : (col += 1) {
            if (line[col] == '#') {
                try out_galaxy_list.append(.{ .row = row, .col = col });
            }
        }
    }
}

fn isRowEmpty(grid: *Grid, row: CoordUnit, size: CoordUnit) bool {
    for (0..size) |col| {
        if (grid[row][col] == '#') return false;
    }
    return true;
}

fn isColEmpty(grid: *Grid, col: CoordUnit, size: CoordUnit) bool {
    for (0..size) |row| {
        if (grid[row][col] == '#') return false;
    }
    return true;
}

fn expandUniverse(galaxies: *ArrayList(Galaxy), grid: *Grid, row_size: CoordUnit, factor: CoordUnit) void {
    var row: CoordUnit = 0;
    var rows_expanded: CoordUnit = 0;
    while (row < row_size) : (row += 1) {
        if (isRowEmpty(grid, row, row_size)) {
            // Push galaxies below lower
            for (galaxies.items) |*galaxy| {
                if (galaxy.row >= rows_expanded and galaxy.row - rows_expanded > row) {
                    galaxy.row += factor;
                }
            }
            rows_expanded += factor;
        }
    }

    var col: CoordUnit = 0;
    var cols_expanded: CoordUnit = 0;
    while (col < row_size) : (col += 1) {
        if (isColEmpty(grid, col, row_size)) {
            // Push galaxies on the right further right
            for (galaxies.items) |*galaxy| {
                if (galaxy.col >= cols_expanded and galaxy.col - cols_expanded > col) {
                    galaxy.col += factor;
                }
            }
            cols_expanded += factor;
        }
    }
}

fn galaxyDistance(galaxy1: *Galaxy, galaxy2: *Galaxy) CoordUnit {
    const row = @max(galaxy1.row, galaxy2.row) - @min(galaxy1.row, galaxy2.row);
    const col = @max(galaxy1.col, galaxy2.col) - @min(galaxy1.col, galaxy2.col);
    return row + col;
}

fn findSumOfGalaxyPaths(galaxies: *ArrayList(Galaxy)) u64 {
    var sum: u64 = 0;
    for (galaxies.items[0 .. galaxies.items.len - 1], 0..) |*galaxy1, idx| {
        for (galaxies.items[idx + 1 ..]) |*galaxy2| {
            sum += galaxyDistance(galaxy1, galaxy2);
        }
    }
    return sum;
}

pub fn solveStar1(galaxies: *ArrayList(Galaxy), grid: *Grid, row_size: CoordUnit) u64 {
    expandUniverse(galaxies, grid, row_size, 1);
    return findSumOfGalaxyPaths(galaxies);
}

pub fn solveStar2(galaxies: *ArrayList(Galaxy), grid: *Grid, row_size: CoordUnit, factor: CoordUnit) u64 {
    expandUniverse(galaxies, grid, row_size, factor - 1);
    return findSumOfGalaxyPaths(galaxies);
}

pub fn main() !void {
    var galaxies = ArrayList(Galaxy).init(ga);
    try parseInput(full, &stored_grid, &galaxies);
    var galaxies_copy = try galaxies.clone();

    const result1 = solveStar1(&galaxies, &stored_grid, grid_size_full);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(
        &galaxies_copy,
        &stored_grid,
        grid_size_full,
        1000000,
    );
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var galaxies = ArrayList(Galaxy).init(ga);
    try parseInput(simple, &stored_grid, &galaxies);
    var galaxies_copy = try galaxies.clone();
    var galaxies_copy2 = try galaxies.clone();

    const result1 = solveStar1(&galaxies, &stored_grid, grid_size_simple);
    try expect(result1 == 374);
    const result2 = solveStar2(&galaxies_copy, &stored_grid, grid_size_simple, 10);
    try expect(result2 == 1030);
    const result3 = solveStar2(
        &galaxies_copy2,
        &stored_grid,
        grid_size_simple,
        100,
    );
    try expect(result3 == 8410);
}

test "full" {
    var galaxies = ArrayList(Galaxy).init(ga);
    try parseInput(full, &stored_grid, &galaxies);
    var galaxies_copy = try galaxies.clone();

    const result1 = solveStar1(&galaxies, &stored_grid, grid_size_full);
    try expect(result1 == 9312968);
    const result2 = solveStar2(
        &galaxies_copy,
        &stored_grid,
        grid_size_full,
        1000000,
    );
    try expect(result2 == 597714117556);
}
