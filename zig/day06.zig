const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-06";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const RaceRecord = struct {
    time: u64,
    distance: u64,
};

fn skipToNextDigit(input: []const u8) usize {
    var char_idx: usize = 0;
    while (char_idx < input.len and !isDigit(input[char_idx])) : (char_idx += 1) {}
    return char_idx;
}

test "goes to first digit" {
    try expect(skipToNextDigit("Time:   34") == 8);
}

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, out_record_list: *ArrayList(RaceRecord)) !void {
    _ = allocator;

    const inputTrimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, inputTrimmed, '\n');
    const time_line = lines_iterator.next().?;
    const distance_line = lines_iterator.next().?;
    var char_idx_time: usize = skipToNextDigit(time_line);
    var char_idx_distance: usize = skipToNextDigit(distance_line);
    while (char_idx_time < time_line.len and char_idx_distance < distance_line.len) {
        var new_record = try out_record_list.addOne();
        const parsed_time = try utils.parseNumberAtStart(u64, time_line[char_idx_time..]);
        new_record.time = parsed_time.value;
        char_idx_time += parsed_time.consumed;
        char_idx_time += skipToNextDigit(time_line[char_idx_time..]);
        const parsed_distance = try utils.parseNumberAtStart(u64, distance_line[char_idx_distance..]);
        new_record.distance = parsed_distance.value;
        char_idx_distance += parsed_distance.consumed;
        char_idx_distance += skipToNextDigit(distance_line[char_idx_distance..]);
    }
}

fn findCombinations(race_record: RaceRecord) u64 {
    var time: u64 = 0;
    var time_start: ?u64 = null;
    while (time <= race_record.time) : (time += 1) {
        const time_travel = race_record.time - time;
        const speed = time;
        const distance = time_travel * speed;
        if (distance > race_record.distance and time_start == null) {
            time_start = time;
        } else if (distance <= race_record.distance and time_start != null) {
            return time - time_start.?;
        }
    }
    return race_record.time - time_start.?;
}

pub fn solveStar1(race_records: *ArrayList(RaceRecord)) u64 {
    var product: u64 = 1;
    for (race_records.items) |race_record| {
        const combs = findCombinations(race_record);
        product *= combs;
    }
    return product;
}

fn findNumberUpperBase10(number: u64) u64 {
    var current: u64 = 10;
    while (current < number) : (current *= 10) {}
    return current;
}

test "finding upper base 10" {
    try expect(findNumberUpperBase10(7) == 10);
    try expect(findNumberUpperBase10(15) == 100);
    try expect(findNumberUpperBase10(1067) == 10_000);
}

fn combineRecords(race_records: *ArrayList(RaceRecord)) RaceRecord {
    var new_record = RaceRecord{ .time = 0, .distance = 0 };
    for (race_records.items) |race_record| {
        new_record.time *= findNumberUpperBase10(race_record.time);
        new_record.distance *= findNumberUpperBase10(race_record.distance);
        new_record.time += race_record.time;
        new_record.distance += race_record.distance;
    }
    return new_record;
}

pub fn solveStar2(race_records: *ArrayList(RaceRecord)) u64 {
    const combined = combineRecords(race_records);
    return findCombinations(combined);
}

pub fn main() !void {
    var race_records = ArrayList(RaceRecord).init(ga);
    try parseInput(ga, full, &race_records);

    const result1 = solveStar1(&race_records);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&race_records);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var race_records = ArrayList(RaceRecord).init(ga);
    try parseInput(ga, simple, &race_records);

    const result1 = solveStar1(&race_records);
    try expect(result1 == 288);
    const result2 = solveStar2(&race_records);
    try expect(result2 == 71503);
}

test "full" {
    var race_records = ArrayList(RaceRecord).init(ga);
    try parseInput(ga, full, &race_records);

    const result1 = solveStar1(&race_records);
    try expect(result1 == 512295);
    const result2 = solveStar2(&race_records);
    try expect(result2 == 36530883);
}
