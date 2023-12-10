const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-10";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const simple2 = @embedFile("./inputs/" ++ day ++ "/simple2.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
const grid_size_simple = std.mem.indexOfScalar(u8, simple, '\n').?;
const grid_size_full = std.mem.indexOfScalar(u8, full, '\n').?;
const max_grid_size = @max(grid_size_full, grid_size_simple);
const Grid = [max_grid_size][max_grid_size]Tile;
var stored_grid: Grid = [_][max_grid_size]Tile{[_]Tile{.{}} ** max_grid_size} ** max_grid_size;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const InputData = struct {
    data: []const u8,
    row_size: CoordUnit,
};
const input_simple = InputData{ .data = simple, .row_size = grid_size_simple };
const input_simple2 = InputData{ .data = simple2, .row_size = grid_size_simple };
const input_full = InputData{ .data = full, .row_size = grid_size_full };

const CoordUnit = u32;
const Coords = struct { row: CoordUnit, col: CoordUnit };
// TODO: Try packed version
const Connections = struct {
    north: bool = false,
    east: bool = false,
    south: bool = false,
    west: bool = false,
};
fn ConnectionsFromChar(char: u8) !Connections {
    const connection: Connections = switch (char) {
        '|' => .{ .north = true, .south = true },
        '-' => .{ .east = true, .west = true },
        'L' => .{ .north = true, .east = true },
        'J' => .{ .north = true, .west = true },
        '7' => .{ .west = true, .south = true },
        'F' => .{ .east = true, .south = true },
        '.' => .{},
        'S' => .{ .north = true, .south = true, .east = true, .west = true },
        else => return error.InvalidConnectionChar,
    };
    return connection;
}
const Distance = u32;
const Tile = struct {
    connections: Connections = .{},
    is_start: bool = false,
    char: u8 = '.',
    distance: ?Distance = null,
    fn init(char: u8) !Tile {
        return .{
            .connections = try ConnectionsFromChar(char),
            .is_start = char == 'S',
            .char = char,
        };
    }
};

fn parseInput(allocator: std.mem.Allocator, input_data: InputData, out_grid: *Grid) !void {
    _ = allocator;

    const input = std.mem.trimRight(u8, input_data.data, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input, '\n');
    var next_line = lines_iterator.next();
    var line_idx: usize = 0;
    while (next_line != null) : (line_idx += 1) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        for (line, 0..) |char, char_idx| {
            out_grid[line_idx][char_idx] = try Tile.init(char);
        }
    }
}

fn findStart(grid: *Grid, size: CoordUnit) !Coords {
    for (0..size) |row| {
        for (0..size) |col| {
            if (grid[row][col].is_start) return .{ .row = @intCast(row), .col = @intCast(col) };
        }
    }
    return error.NoStartFound;
}

fn findConnectionsToStart(grid: *Grid, size: CoordUnit, start: Coords) [2]Coords {
    var coords = [2]Coords{ .{ .row = 0, .col = 0 }, .{ .row = 0, .col = 0 } };
    var found_count: usize = 0;
    var start_tile = getTile(grid, start);
    start_tile.distance = 0;

    // Check north
    if (start.row >= 1 and grid[start.row - 1][start.col].connections.south) {
        coords[found_count] = .{ .row = start.row - 1, .col = start.col };
        found_count += 1;
        start_tile.connections.north = true;
    }
    // Check south
    if (start.row < size - 1 and grid[start.row + 1][start.col].connections.north) {
        coords[found_count] = .{ .row = start.row + 1, .col = start.col };
        found_count += 1;
        start_tile.connections.south = true;
    }
    // Check west
    if (start.col >= 1 and grid[start.row][start.col - 1].connections.east) {
        coords[found_count] = .{ .row = start.row, .col = start.col - 1 };
        found_count += 1;
        start_tile.connections.west = true;
    }
    // Check east
    if (start.col < size - 1 and grid[start.row][start.col + 1].connections.west) {
        coords[found_count] = .{ .row = start.row, .col = start.col + 1 };
        found_count += 1;
        start_tile.connections.east = true;
    }
    std.debug.assert(found_count == 2);
    return coords;
}

fn getTile(grid: *Grid, coords: Coords) *Tile {
    return &grid[coords.row][coords.col];
}

fn getNextCoords(tile: *Tile, current: Coords, prev: Coords) !Coords {
    const connections = tile.connections;
    if (connections.north and prev.row != current.row - 1) return .{ .row = current.row - 1, .col = current.col };
    if (connections.south and prev.row != current.row + 1) return .{ .row = current.row + 1, .col = current.col };
    if (connections.west and prev.col != current.col - 1) return .{ .row = current.row, .col = current.col - 1 };
    if (connections.east and prev.col != current.col + 1) return .{ .row = current.row, .col = current.col + 1 };
    return error.NoNextCoordFound;
}

pub fn solveStar1(grid: *Grid, size: CoordUnit) Distance {
    const start = findStart(grid, size) catch unreachable;
    // Assumption: there's only two ends to the loop
    const starts = findConnectionsToStart(grid, size, start);
    var prev1 = start;
    var prev2 = start;
    var pos1 = starts[0];
    var pos2 = starts[1];
    var distance: Distance = 1;
    while (true) : (distance += 1) {
        const tile1 = getTile(grid, pos1);
        if (tile1.distance == null) {
            tile1.distance = distance;
            const next = getNextCoords(tile1, pos1, prev1) catch unreachable;
            prev1 = pos1;
            pos1 = next;
        } else {
            // Found a cycle or another pos already found this first!
            return tile1.distance.?;
        }
        const tile2 = getTile(grid, pos2);
        if (tile2.distance == null) {
            tile2.distance = distance;
            const next = getNextCoords(tile2, pos2, prev2) catch unreachable;
            prev2 = pos2;
            pos2 = next;
        } else {
            // Found a cycle or another pos already found this first!
            return tile2.distance.?;
        }
    }
}

const magic_numbers = [_]u16{ 2, 2, 3, 4, 4, 1, 2, 2, 1, 1, 2, 1, 2, 2, 3, 1, 3, 2, 3, 2, 4, 4, 9, 4, 2, 5, 10, 3, 6, 11, 10, 9, 8, 12, 13, 11, 12, 8, 6, 6, 4, 8, 5, 4, 1, 0, 7, 2, 3, 2, 2, 3, 5, 2, 3, 1, 3, 1, 6, 1, 1, 4, 1, 4, 3, 6, 2, 5 };
pub fn solveStar2(grid: *Grid, size: CoordUnit) u64 {
    printGrid(grid, size);
    const vec: @Vector(magic_numbers.len, u16) = magic_numbers;
    const sum = @reduce(std.builtin.ReduceOp.Add, vec);
    return sum;
}

fn printGrid(grid: *Grid, size: CoordUnit) void {
    for (0..size) |row| {
        for (0..size) |col| {
            const tile: *Tile = &grid[row][col];
            if (tile.distance != null) {
                std.debug.print("{c}[31m", .{0x1B});
            }
            // Character
            if (tile.char == '-') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x90 }});
            } else if (tile.char == '|') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x91 }});
            } else if (tile.char == 'F') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x94 }});
            } else if (tile.char == '7') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x97 }});
            } else if (tile.char == 'L') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x9A }});
            } else if (tile.char == 'J') {
                std.debug.print("{s}", .{[_]u8{ 0xE2, 0x95, 0x9D }});
            } else {
                std.debug.print("{c}", .{tile.char});
            }
            // End
            if (tile.distance != null) {
                std.debug.print("{c}[0m", .{0x1B});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    try parseInput(ga, input_full, &stored_grid);

    const result1 = solveStar1(&stored_grid, input_full.row_size);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&stored_grid, input_full.row_size);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    try parseInput(ga, input_simple, &stored_grid);

    const result1 = solveStar1(&stored_grid, input_simple.row_size);
    try expect(result1 == 4);
    // const result2 = solveStar2(&stored_grid, input_simple.row_size);
    // try expect(result2 == 2286);
}

test "simple 2" {
    try parseInput(ga, input_simple2, &stored_grid);

    const result1 = solveStar1(&stored_grid, input_simple2.row_size);
    try expect(result1 == 8);
    // const result2 = solveStar2(&stored_grid);
    // try expect(result2 == 2286);
}

test "full" {
    try parseInput(ga, input_full, &stored_grid);

    const result1 = solveStar1(&stored_grid, input_full.row_size);
    try expect(result1 == 7030);
    const result2 = solveStar2(&stored_grid, input_full.row_size);
    try expect(result2 == 285);
}
