const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-05";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

const Range = struct {
    dest: u64,
    source: u64,
    length: u64,
};

const Map = struct {
    from: []const u8,
    to: []const u8,
    ranges: ArrayList(Range),
};

fn parseMap(allocator: std.mem.Allocator, input: []const u8, out_map: *Map) !void {
    var line_iterator = std.mem.splitScalar(u8, input, '\n');
    var next_line = line_iterator.next();
    var line = next_line.?;
    // Parse the map header
    const first_minus_loc = std.mem.indexOfScalar(u8, line, '-').?;
    out_map.from = line[0..first_minus_loc];
    const to_start = first_minus_loc + 4;
    std.debug.assert(to_start < line.len);
    const space_after_map_name_loc = to_start + std.mem.indexOfScalar(u8, line[to_start..], ' ').?;
    out_map.to = line[to_start..space_after_map_name_loc];

    // Parse ranges
    out_map.ranges = ArrayList(Range).init(allocator);
    next_line = line_iterator.next();
    while (next_line != null) {
        line = next_line.?;
        next_line = line_iterator.next();

        var new_range = try out_map.ranges.addOne();
        var char_idx: usize = 0;
        const dest = try utils.parseNumberAtStart(u64, line);
        new_range.dest = dest.value;
        char_idx += dest.consumed + 1;
        const source = try utils.parseNumberAtStart(u64, line[char_idx..]);
        new_range.source = source.value;
        char_idx += source.consumed + 1;
        const length = try utils.parseNumberAtStart(u64, line[char_idx..]);
        new_range.length = length.value;
    }
}

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, seed_list: *ArrayList(u64), map_list: *ArrayList(Map)) !void {
    const inputTrimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var object_iterator = std.mem.splitSequence(u8, inputTrimmed, "\n\n");
    var next_object = object_iterator.next();
    while (next_object != null) {
        const object = next_object.?;
        next_object = object_iterator.next();

        std.debug.print("Object is {s}\n\n", .{object});

        if (seed_list.items.len == 0) {
            // First one; initialize the seeds
            var char_idx: usize = 7;
            while (char_idx < object.len) {
                const parsed = try utils.parseNumberAtStart(u64, object[char_idx..]);
                try seed_list.append(parsed.value);
                char_idx += parsed.consumed + 1;
            }
            continue;
        }
        // Otherwise, we have one of the maps here
        const new_map = try map_list.addOne();
        try parseMap(allocator, object, new_map);
    }
}

fn mapValue(value: u64, range_list: *ArrayList(Range)) u64 {
    for (range_list.items) |*range| {
        if (value >= range.source and value < range.source + range.length) {
            return value - range.source + range.dest;
        }
    }
    return value;
}

fn findSeedLocation(value: u64, map_list: *ArrayList(Map)) u64 {
    var result = value;
    for (map_list.items) |*map| {
        result = mapValue(result, &map.ranges);
    }
    return result;
}

pub fn solveStar1(seed_list: *ArrayList(u64), map_list: *ArrayList(Map)) u64 {
    var min: ?u64 = null;
    for (seed_list.items) |seed| {
        const location = findSeedLocation(seed, map_list);
        if (min == null) {
            min = location;
        } else {
            min = @min(min.?, location);
        }
    }
    return min.?;
}

pub fn solveStar2(seed_list: *ArrayList(u64), map_list: *ArrayList(Map)) u64 {
    var min: ?u64 = null;
    var seed_idx: usize = 0;
    while (seed_idx < seed_list.items.len) : (seed_idx += 2) {
        var seed = seed_list.items[seed_idx];
        const seed_len = seed_list.items[seed_idx + 1];
        const seed_bound = seed + seed_list.items[seed_idx + 1];
        const report_freq: u32 = 1_000_000;
        var next_report: u32 = report_freq;
        var seed_counter: usize = 0;
        std.debug.print("SEED PAIR {} of {}: len is {}\n", .{ seed_idx + 1, seed_list.items.len / 2, seed_len });
        while (seed < seed_bound) : (seed += 1) {
            const location = findSeedLocation(seed, map_list);
            if (min == null) {
                min = location;
            } else {
                min = @min(min.?, location);
            }
            if (next_report == 0) {
                std.debug.print("seed {} of {}\n", .{ seed_counter, seed_len });
                next_report = report_freq;
            }
            next_report -= 1;
            seed_counter += 1;
        }
    }
    return min.?;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // We deallocate by finishing the program anyway :)
    const allocator = arena.allocator();
    // seed_list: *ArrayList(u32), map_list: *ArrayList(Map)
    var seed_list = ArrayList(u64).init(allocator);
    var map_list = ArrayList(Map).init(allocator);
    try parseInput(allocator, full, &seed_list, &map_list);

    const result1 = solveStar1(&seed_list, &map_list);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&seed_list, &map_list);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const allocator = std.testing.allocator;
    var seed_list = ArrayList(u64).init(allocator);
    var map_list = ArrayList(Map).init(allocator);
    defer {
        for (map_list.items) |item| item.ranges.deinit();
        map_list.deinit();
        seed_list.deinit();
    }
    try parseInput(allocator, simple, &seed_list, &map_list);

    const result = solveStar1(&seed_list, &map_list);
    try expect(result == 35);
}

test "star 1 full" {
    const allocator = std.testing.allocator;
    var seed_list = ArrayList(u64).init(allocator);
    var map_list = ArrayList(Map).init(allocator);
    defer {
        for (map_list.items) |item| item.ranges.deinit();
        map_list.deinit();
        seed_list.deinit();
    }
    try parseInput(allocator, full, &seed_list, &map_list);

    const result = solveStar1(&seed_list, &map_list);
    try expect(result == 174137457);
}

test "star 2 simple" {
    const allocator = std.testing.allocator;
    var seed_list = ArrayList(u64).init(allocator);
    var map_list = ArrayList(Map).init(allocator);
    defer {
        for (map_list.items) |item| item.ranges.deinit();
        map_list.deinit();
        seed_list.deinit();
    }
    try parseInput(allocator, simple, &seed_list, &map_list);

    const result = solveStar2(&seed_list, &map_list);
    try expect(result == 46);
}

// test "star 2 full" {
//     const allocator = std.testing.allocator;
//     var cube_sets = ArrayList(CubeSet).init(allocator);
//     try parseInput(allocator, full, &cube_sets);

//     const result = solveStar2(&cube_sets);
//     try expect(result == 67953);
// }
