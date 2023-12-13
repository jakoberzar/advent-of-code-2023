const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-12";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const GroupSize = u8;
const RecordLen = u16;
const Row = struct {
    id: u16,
    record: []u8,
    groups: ArrayList(GroupSize),
    questions: ArrayList(RecordLen),
    pub fn format(
        self: Row,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} ", .{self.record});

        for (self.groups.items) |value| {
            try writer.print("{},", .{value});
        }
        try writer.print("\n", .{});

        var char_idx: RecordLen = 0;
        var question_idx: RecordLen = 0;
        while (char_idx < self.record.len and question_idx < self.questions.items.len) : (char_idx += 1) {
            if (char_idx == self.questions.items[question_idx]) {
                try writer.print("^", .{});
                question_idx += 1;
            } else {
                try writer.print(" ", .{});
            }
        }
        try writer.writeAll("");
    }
};

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, out_row_list: *ArrayList(Row)) !void {
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input_trimmed, '\n');
    var next_line = lines_iterator.next();
    var row_idx: u16 = 1;
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        var split_space_iterator = std.mem.splitScalar(u8, line, ' ');
        const new_row = try out_row_list.addOne();
        // Id
        new_row.id = row_idx;
        // Record
        const record_string = split_space_iterator.next().?;
        new_row.record = try allocator.alloc(u8, record_string.len);
        std.mem.copyForwards(u8, new_row.record, record_string);
        // Questions
        new_row.questions = ArrayList(RecordLen).init(allocator);
        for (record_string, 0..) |char, idx| {
            if (char == '?') try new_row.questions.append(@intCast(idx));
        }
        // Groups
        new_row.groups = ArrayList(GroupSize).init(allocator);
        var num_string = split_space_iterator.next().?;
        var char_idx: usize = 0;
        while (char_idx < num_string.len) {
            const parsed = try utils.parseNumberAtStart(GroupSize, num_string[char_idx..]);
            char_idx += parsed.consumed + 1;
            try new_row.groups.append(parsed.value);
        }
        row_idx += 1;
    }
}

fn checkFullRow(row: *const Row, last_result: *const PartialResult) bool {
    // Check passed data
    const start = last_result.next_start;
    var group_idx: u32 = last_result.next_group;
    if (start >= row.record.len) {
        return group_idx == row.groups.items.len;
    }
    if (group_idx > row.groups.items.len) {
        return false;
    }
    if (last_result.groups_need > row.record.len - start) {
        return false;
    }

    var currently_in_group = false;
    var counted: GroupSize = 0;
    for (row.record[start..], start..) |value, record_idx| {
        _ = record_idx;

        if (value == '.' or value == '?') { // We treat ? as . by default for optimization
            if (currently_in_group) {
                if (counted != row.groups.items[group_idx]) {
                    return false;
                }
                // Prepare for next group
                currently_in_group = false;
                group_idx += 1;
                counted = 0;
            }
        } else if (value == '#') {
            if (!currently_in_group) {
                if (group_idx >= row.groups.items.len) {
                    return false;
                }
                currently_in_group = true;
            }
            counted += 1;
            if (counted > row.groups.items[group_idx]) {
                return false;
            }
        }
    }
    // Imagine there's one more field last to correct the state
    if (currently_in_group) {
        if (counted != row.groups.items[group_idx]) {
            return false;
        }
        // Prepare for next group
        currently_in_group = false;
        group_idx += 1;
        counted = 0;
    }
    if (group_idx != row.groups.items.len) {
        return false;
    }
    return true;
}

const PartialResult = struct {
    status: bool,
    next_start: RecordLen,
    groups_need: RecordLen,
    next_group: u32,
};

// Fails if there is already something incompatible (at the start).
fn checkPartial(row: *const Row, last_result: *const PartialResult) PartialResult {
    var result = last_result.*;
    result.status = false;
    // Check passed data
    const start = last_result.next_start;
    var group_idx: u32 = last_result.next_group;
    if (start >= row.record.len) {
        result.status = group_idx == row.groups.items.len;
        return result;
    }
    if (group_idx > row.groups.items.len) {
        return result;
    }
    if (last_result.groups_need > row.record.len - start) {
        return result;
    }

    var currently_in_group = false;
    var counted: GroupSize = 0;
    for (row.record[start..], start..) |value, record_idx| {
        if (value == '.') {
            if (currently_in_group) {
                if (counted != row.groups.items[group_idx]) {
                    return result;
                }
                // Prepare for next group
                currently_in_group = false;
                group_idx += 1;
                counted = 0;
                // Update successful groups
                result.next_group = group_idx;
                result.next_start = @intCast(record_idx);
                result.groups_need -= row.groups.items[group_idx - 1];
                if (group_idx < row.groups.items.len) {
                    result.groups_need -= 1;
                }
            }
        } else if (value == '#') {
            if (!currently_in_group) {
                if (group_idx >= row.groups.items.len) {
                    return result;
                }
                currently_in_group = true;
            }
            counted += 1;
            if (counted > row.groups.items[group_idx]) {
                return result;
            }
        } else if (value == '?') {
            result.status = true;
            return result;
        }
    }
    // Imagine there's one more field last to correct the state
    if (currently_in_group) {
        if (counted != row.groups.items[group_idx]) {
            return result;
        }
        // Prepare for next group
        currently_in_group = false;
        group_idx += 1;
        counted = 0;
        // Update successful groups
        result.next_group = group_idx;
        result.next_start = @intCast(row.record.len);
        result.groups_need -= row.groups.items[group_idx - 1];
        if (group_idx < row.groups.items.len) {
            result.groups_need -= 1;
        }
    }
    if (group_idx != row.groups.items.len) {
        return result;
    }
    result.status = true;
    return result;
}

const CacheType = ArrayList(?u64);
fn getCacheIdx(row: *Row, question_idx: RecordLen, last_result: *const PartialResult) usize {
    return question_idx * (row.groups.items.len + 1) + last_result.next_group;
}

fn solveAtIndex(row: *Row, cache: *CacheType, question_idx: RecordLen, last_result: *const PartialResult) u64 {
    const question_pos = row.questions.items[question_idx];
    const is_final = question_idx == row.questions.items.len - 1;
    // const report_freq = 45;
    // if (row.questions.items.len > report_freq and question_idx < row.questions.items.len - report_freq) {
    //     std.debug.print("[{}]:{} - {s}\n", .{ row.id, question_idx, row.record });
    // }

    if (last_result.groups_need == 0) {
        // We only need to fill the rest with dots.
        // This means that there is only one option remaining, we just need to check if it works.
        if (checkFullRow(row, last_result)) {
            return 1;
        }
    }
    const enable_cache = question_pos > 0 and row.record[question_pos - 1] == '.';
    if (enable_cache) {
        const cache_idx = getCacheIdx(row, question_idx, last_result);
        if (cache.items[cache_idx]) |cached| {
            return cached;
        }
    }

    var solution_count: u64 = 0;
    // Try damaged
    row.record[question_pos] = '#';
    if (is_final) {
        if (checkFullRow(row, last_result)) {
            solution_count += 1;
        }
    } else {
        const partial_check = checkPartial(row, last_result);
        if (partial_check.status) {
            solution_count += solveAtIndex(row, cache, question_idx + 1, &partial_check);
        }
    }
    // Try operational
    row.record[question_pos] = '.';
    if (is_final) {
        if (checkFullRow(row, last_result)) {
            solution_count += 1;
        }
    } else {
        const partial_check = checkPartial(row, last_result);
        if (partial_check.status) {
            solution_count += solveAtIndex(row, cache, question_idx + 1, &partial_check);
        }
    }

    // Revert back
    row.record[question_pos] = '?';

    // Store to cache
    if (enable_cache) {
        const cache_idx = getCacheIdx(row, question_idx, last_result);
        cache.items[cache_idx] = solution_count;
    }
    return solution_count;
}

fn solveRow(row: *Row) u64 {
    if (row.questions.items.len == 0) return 1;

    var groups_need: RecordLen = 0;
    for (row.groups.items) |group| {
        if (groups_need > 0) groups_need += 1;
        groups_need += group;
    }
    const partial_result = PartialResult{
        .status = true,
        .next_group = 0,
        .next_start = 0,
        .groups_need = groups_need,
    };

    // Init cache
    const cache_size = row.questions.items.len * (row.groups.items.len + 1);
    // Using arena here instead of std.heap.page_allocator decreases time with no observable memory increase.
    // from 59.0 ms ±  10.3 ms    [User: 31.3 ms, System: 25.9 ms]
    // to   34.9 ms ±  11.5 ms    [User: 33.6 ms, System: 0.9 ms]
    var cache = CacheType.init(ga);
    defer cache.deinit();
    cache.appendNTimes(null, cache_size) catch unreachable;

    return solveAtIndex(row, &cache, 0, &partial_result);
}

pub fn solveStar1(rows: *ArrayList(Row)) u64 {
    var sum: u64 = 0;
    for (rows.items) |*row| {
        const solutions = solveRow(row);
        sum += solutions;
        // std.debug.print("{s} - {} arrangements\n", .{ row.record, solutions });
    }
    return sum;
}

fn expandRow(row: *Row) !void {
    const old_record = row.record;
    defer ga.free(old_record);
    row.record = try std.mem.join(ga, "?", &[_][]u8{
        old_record,
        old_record,
        old_record,
        old_record,
        old_record,
    });

    const old_group = try ga.alloc(u8, row.groups.items.len);
    defer ga.free(old_group);
    std.mem.copyForwards(u8, old_group, row.groups.items);
    try row.groups.ensureTotalCapacity(row.groups.items.len * 5);
    for (1..5) |_| {
        try row.groups.appendSlice(old_group);
    }

    const initial_questions_size = row.questions.items.len;
    try row.groups.ensureTotalCapacity(row.groups.items.len * 5 + 4);
    for (1..5) |times| {
        const starting: RecordLen = @intCast(times * (old_record.len + 1)); // 3, 6, 9
        try row.questions.append(starting - 1); // 2, 5, 8
        for (0..initial_questions_size) |idx| {
            const original_pos = row.questions.items[idx];
            try row.questions.append(starting + original_pos); // 4, 7, 10
        }
    }
}

pub fn solveStar2(rows: *ArrayList(Row)) u64 {
    var sum: u64 = 0;
    for (rows.items, 1..) |*row, line| {
        _ = line;

        expandRow(row) catch unreachable;
        // std.debug.print("-- LINE {}:\n{s}\n--\n", .{ line, row });
        const solutions = solveRow(row);
        sum += solutions;
        // std.debug.print("{s} - {} arrangements\n", .{ row.record, solutions });
    }
    return sum;
}

pub fn main() !void {
    var rows = ArrayList(Row).init(ga);
    try parseInput(ga, full, &rows);

    const result1 = solveStar1(&rows);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&rows);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var rows = ArrayList(Row).init(ga);
    try parseInput(ga, simple, &rows);

    const result1 = solveStar1(&rows);
    try expect(result1 == 21);
    const result2 = solveStar2(&rows);
    try expect(result2 == 525152);
}

// test "full" {
//     var rows = ArrayList(Row).init(ga);
//     try parseInput(ga, full, &rows);

//     const result1 = solveStar1(&rows);
//     try expect(result1 == 2278);
//     // const result2 = solveStar2(&rows);
//     // try expect(result2 == 67953);
// }
