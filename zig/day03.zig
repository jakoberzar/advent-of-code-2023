const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const print = std.debug.print;

const utils = @import("utils.zig");

const day = "day-03";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
const grid_size_simple = std.mem.indexOfScalar(u8, simple, '\n').?;
const grid_size_full = std.mem.indexOfScalar(u8, full, '\n').?;
const max_grid_size = @max(grid_size_full, grid_size_simple);
const Grid = [max_grid_size][max_grid_size]u8;
var stored_grid: Grid = [_][max_grid_size]u8{[_]u8{0} ** max_grid_size} ** max_grid_size; // Copy of input but without the newlines.

const InputData = struct {
    data: []const u8,
    row_size: usize,
};
const input_simple = InputData{ .data = simple, .row_size = grid_size_simple };
const input_full = InputData{ .data = full, .row_size = grid_size_full };

// We just need a fixed array. A copy of input will suffice.
fn parseInput(input: InputData, out_grid: *Grid) !void {
    var row: usize = 0;
    const trimmed_input = std.mem.trimRight(u8, input.data, &[_]u8{0});
    var input_window = std.mem.window(u8, trimmed_input, input.row_size, input.row_size + 1);
    var current_input_window = input_window.next();
    while (current_input_window != null and row < out_grid.len) {
        const current_input = current_input_window.?[0..input.row_size]; // Bug in Zig's window? Somehow the size was larger than input.row_size.
        // print("Starting row {}: |{s}|, len: {}\n", .{ row, current_input, current_input.len });
        std.mem.copyForwards(u8, out_grid[row][0..input.row_size], current_input);
        // print("Finished row {}: |{s}|\n", .{ row, out_grid[row][0..input.row_size] });
        current_input_window = input_window.next();
        row += 1;
    }
}

fn sumEnginePartsAround(grid: *Grid, symbol_row: usize, symbol_col: usize) u64 {
    var sum: u64 = 0;
    var row: usize = symbol_row - 1;
    while (row <= symbol_row + 1) : (row += 1) {
        var col: usize = symbol_col - 1;
        while (col <= symbol_col + 1) : (col += 1) {
            if (isDigit(grid[row][col])) {
                // Find digit start
                var digit_start = col;
                while (digit_start > 0 and isDigit(grid[row][digit_start])) : (digit_start -= 1) {}
                if (!isDigit(grid[row][digit_start])) digit_start += 1;
                // Get the number
                const parsed_digit_result = utils.parseNumberAtStart(u32, grid[row][digit_start..]) catch unreachable;
                sum += parsed_digit_result.value;
                // Delete the number to prevent it from happening twice
                var overwrite_col = digit_start;
                while (overwrite_col < digit_start + parsed_digit_result.consumed) : (overwrite_col += 1) {
                    grid[row][overwrite_col] = 'O';
                }
            }
        }
    }
    return sum;
}

fn isSymbol(char: u8) bool {
    if (char == '.') return false;
    if (char == 'O') return false;
    if (isDigit(char)) return false;
    return true;
}

const SumGridPredicate = fn (char: u8) bool;
const SumGridMap = fn (grid: *Grid, row: usize, col: usize) u64;
fn sumInnerGridFieldIf(grid: *Grid, row_size: usize, comptime predicate: SumGridPredicate, comptime map: SumGridMap) u64 {
    var sum: u64 = 0;
    var row: usize = 1;
    while (row < row_size - 1) : (row += 1) {
        var col: usize = 1;
        while (col < row_size - 1) : (col += 1) {
            if (predicate(grid[row][col])) {
                sum += map(grid, row, col);
            }
        }
    }
    return sum;
}

pub fn solveStar1(grid: *Grid, row_size: usize) u64 {
    return sumInnerGridFieldIf(grid, row_size, isSymbol, sumEnginePartsAround);
}

fn isAsterrisk(char: u8) bool {
    return char == '*';
}

fn getGearRatio(grid: *Grid, symbol_row: usize, symbol_col: usize) u64 {
    var product: u64 = 1;
    var parts_amount: usize = 0;
    var row: usize = symbol_row - 1;
    while (row <= symbol_row + 1) : (row += 1) {
        var col: usize = symbol_col - 1;
        while (col <= symbol_col + 1) : (col += 1) {
            if (isDigit(grid[row][col])) {
                if (parts_amount == 2) {
                    // We already found 2 parts before, this is the third one -> not a gear
                    return 0;
                }
                // Find digit start
                var digit_start = col;
                while (digit_start > 0 and isDigit(grid[row][digit_start])) : (digit_start -= 1) {}
                if (!isDigit(grid[row][digit_start])) digit_start += 1;
                // Get the number
                const parsed_digit_result = utils.parseNumberAtStart(u32, grid[row][digit_start..]) catch unreachable;
                parts_amount += 1;
                product *= parsed_digit_result.value;
                // Skip the number to prevent counting it twice
                const digit_end = digit_start + parsed_digit_result.consumed - 1;
                col = digit_end;
            }
        }
    }
    return if (parts_amount == 2) product else 0;
}

pub fn solveStar2(grid: *Grid, row_size: usize) u64 {
    return sumInnerGridFieldIf(grid, row_size, isAsterrisk, getGearRatio);
}

pub fn main() !void {
    try parseInput(input_full, &stored_grid);
    const result1 = solveStar1(&stored_grid, input_full.row_size);
    print("Star 1 result is {}\n", .{result1});

    // Star 1 mutated the array, so reparse to get an unmodified copy.
    try parseInput(input_full, &stored_grid);
    const result2 = solveStar2(&stored_grid, input_full.row_size);
    print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    try parseInput(input_simple, &stored_grid);

    const result = solveStar1(&stored_grid, input_simple.row_size);
    try expect(result == 4361);
}

test "star 1 full" {
    try parseInput(input_full, &stored_grid);

    const result = solveStar1(&stored_grid, input_full.row_size);
    try expect(result == 535078);
}

test "star 2 simple" {
    try parseInput(input_simple, &stored_grid);

    const result = solveStar2(&stored_grid, input_simple.row_size);
    try expect(result == 467835);
}

test "star 2 full" {
    try parseInput(input_full, &stored_grid);

    const result = solveStar2(&stored_grid, input_full.row_size);
    try expect(result == 75312571);
}
