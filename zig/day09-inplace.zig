const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-09";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const NumSeq = ArrayList(i32);

fn parseInput(allocator: std.mem.Allocator, input: [:0]const u8, out_sequences: *ArrayList(NumSeq)) !void {
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input_trimmed, '\n');
    var next_line = lines_iterator.next();
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        try out_sequences.append(NumSeq.init(allocator));
        const seq: *NumSeq = &out_sequences.items[out_sequences.items.len - 1];
        var num_iterator = std.mem.splitScalar(u8, line, ' ');
        var next_num = num_iterator.next();
        while (next_num != null) {
            const parsed = try std.fmt.parseInt(i32, next_num.?, 10);
            try seq.append(parsed);
            next_num = num_iterator.next();
        }
    }
}

fn allValuesZero(sequence: *NumSeq) bool {
    for (sequence.items) |n| {
        if (n != 0) return false;
    }
    return true;
}

fn createLowerLayer(sequence: *NumSeq) void {
    for (sequence.items[0 .. sequence.items.len - 1], 0..) |n, idx| {
        sequence.items[idx] = sequence.items[idx + 1] - n;
    }
}

fn getNext(sequence: *NumSeq) i32 {
    if (allValuesZero(sequence)) return 0;

    // Create lower layer
    createLowerLayer(sequence);
    const last = sequence.pop();
    // Get value for next element
    const child_next = getNext(sequence);
    const next = last + child_next;
    // std.debug.print("For slice ending {}, child next is {} and next is {}\n", .{ last, child_next, next });
    return next;
}

fn getPrevious(sequence: *NumSeq) i32 {
    if (allValuesZero(sequence)) return 0;

    // Create lower layer
    const first = sequence.items[0];
    createLowerLayer(sequence);
    _ = sequence.pop();
    // Get value for previous element
    const child_previous = getPrevious(sequence);
    const previous = first - child_previous;
    // std.debug.print("For slice [{} {}], child previous is {} and previous is {}\n", .{ sequence.items[0], sequence.items[1], child_previous, previous });
    return previous;
}

pub fn solveStar1(sequences: *ArrayList(NumSeq)) i64 {
    var sum: i64 = 0;
    for (sequences.items) |*sequence| {
        const next = getNext(sequence);
        sum += next;
    }
    return sum;
}

pub fn solveStar2(sequences: *ArrayList(NumSeq)) i64 {
    var sum: i64 = 0;
    for (sequences.items) |*sequence| {
        const previous = getPrevious(sequence);
        sum += previous;
    }
    return sum;
}

fn copySequences(sequences: *ArrayList(NumSeq)) !ArrayList(NumSeq) {
    const sequences_copy = try sequences.clone();
    for (sequences_copy.items, 0..) |_, idx| {
        sequences_copy.items[idx] = try sequences.items[idx].clone();
    }
    return sequences_copy;
}

pub fn main() !void {
    var sequences = ArrayList(NumSeq).init(ga);
    try parseInput(ga, full, &sequences);
    var sequences_copy = try copySequences(&sequences);

    const result1 = solveStar1(&sequences);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&sequences_copy);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var sequences = ArrayList(NumSeq).init(ga);
    try parseInput(ga, simple, &sequences);
    var sequences_copy = try copySequences(&sequences);

    const result1 = solveStar1(&sequences);
    try expect(result1 == 114);
    const result2 = solveStar2(&sequences_copy);
    try expect(result2 == 2);
}

test "full" {
    var sequences = ArrayList(NumSeq).init(ga);
    try parseInput(ga, full, &sequences);
    var sequences_copy = try copySequences(&sequences);

    const result1 = solveStar1(&sequences);
    try expect(result1 == 1581679977);
    const result2 = solveStar2(&sequences_copy);
    try expect(result2 == 889);
}
