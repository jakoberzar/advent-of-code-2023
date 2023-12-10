const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-04";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");

const Card = struct {
    winning: []u8,
    picked: []u8,
};

fn addNumbersToStore(input: []const u8, out_number_store: *ArrayList(u8)) !void {
    var char_idx: usize = 0;
    while (char_idx < input.len) : (char_idx += 1) {
        if (!isDigit(input[char_idx])) continue;
        const parsed_number = try utils.parseNumberAtStart(u8, input[char_idx..]);
        try out_number_store.append(parsed_number.value);
        char_idx += parsed_number.consumed;
        // Space after next number is skipped by loop increment
    }
}

fn parseInput(input: [:0]const u8, out_card_list: *ArrayList(Card), out_number_store: *ArrayList(u8)) !void {
    var amount_winning: ?usize = null;
    var amount_picked: ?usize = null;
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input_trimmed, '\n');
    var next_line = lines_iterator.next();
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        var colonSplitIter = std.mem.splitScalar(u8, line, ':');
        _ = colonSplitIter.next();
        var cardsStringSplitIter = std.mem.splitScalar(u8, colonSplitIter.next().?, '|');
        try addNumbersToStore(cardsStringSplitIter.next().?, out_number_store);
        if (amount_winning == null) amount_winning = out_number_store.items.len;
        try addNumbersToStore(cardsStringSplitIter.next().?, out_number_store);
        if (amount_picked == null) amount_picked = out_number_store.items.len - amount_winning.?;

        _ = try out_card_list.addOne();
    }
    const numbers_per_card = amount_winning.? + amount_picked.?;
    for (out_card_list.items, 0..) |*card, i| {
        const picked_start = i * numbers_per_card + amount_winning.?;
        card.winning = out_number_store.items[i * numbers_per_card .. picked_start];
        card.picked = out_number_store.items[picked_start .. picked_start + amount_picked.?];
    }
}

// Optimization idea - this could be precomputed for every card and instead input to both functions.
fn getCardWins(card: *Card) u6 {
    var wins: u6 = 0;
    for (card.winning) |winning_number| {
        if (std.mem.indexOfScalar(u8, card.picked, winning_number) != null) {
            wins += 1;
        }
    }
    return wins;
}

pub fn solveStar1(card_list: *const ArrayList(Card)) u64 {
    var sum: u64 = 0;
    for (card_list.items) |*card| {
        const wins = getCardWins(card);
        if (wins > 0) {
            sum += @as(u64, 1) << (wins - 1);
        }
    }
    return sum;
}

pub fn solveStar2(allocator: std.mem.Allocator, card_list: *const ArrayList(Card)) u64 {
    var copies_map = ArrayList(u64).initCapacity(allocator, card_list.items.len) catch unreachable;
    defer copies_map.deinit();
    copies_map.appendNTimes(1, card_list.items.len) catch unreachable;
    var sum: u64 = 0;
    for (card_list.items, 0..) |*card, i| {
        const self_copies = copies_map.items[i];
        const wins = getCardWins(card);
        var copy_idx: usize = 1;
        while (copy_idx <= wins and i + copy_idx < card_list.items.len) : (copy_idx += 1) {
            copies_map.items[i + copy_idx] = copies_map.items[i + copy_idx] + self_copies;
        }
        sum += self_copies;
    }
    return sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // We deallocate by finishing the program anyway :)
    const allocator = arena.allocator();
    var cards = ArrayList(Card).init(allocator);
    var number_store = ArrayList(u8).init(allocator);
    try parseInput(full, &cards, &number_store);

    const result1 = solveStar1(&cards);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(allocator, &cards);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "star 1 simple" {
    const allocator = std.testing.allocator;
    var cards = ArrayList(Card).init(allocator);
    defer cards.deinit();
    var number_store = ArrayList(u8).init(allocator);
    defer number_store.deinit();
    try parseInput(simple, &cards, &number_store);

    const result = solveStar1(&cards);
    try expect(result == 13);
}

test "star 1 full" {
    const allocator = std.testing.allocator;
    var cards = ArrayList(Card).init(allocator);
    defer cards.deinit();
    var number_store = ArrayList(u8).init(allocator);
    defer number_store.deinit();
    try parseInput(full, &cards, &number_store);

    const result = solveStar1(&cards);
    try expect(result == 20407);
}

test "star 2 simple" {
    const allocator = std.testing.allocator;
    var cards = ArrayList(Card).init(allocator);
    defer cards.deinit();
    var number_store = ArrayList(u8).init(allocator);
    defer number_store.deinit();
    try parseInput(simple, &cards, &number_store);

    const result = solveStar2(allocator, &cards);
    try expect(result == 30);
}

test "star 2 full" {
    const allocator = std.testing.allocator;
    var cards = ArrayList(Card).init(allocator);
    defer cards.deinit();
    var number_store = ArrayList(u8).init(allocator);
    defer number_store.deinit();
    try parseInput(full, &cards, &number_store);

    const result = solveStar2(allocator, &cards);
    try expect(result == 23806951);
}
