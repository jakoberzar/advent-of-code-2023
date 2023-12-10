const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-07";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const Strength = u8;
const Bid = u16;
const HandSize = u3;

const CardCount = struct {
    count: HandSize = 0,
    card: ?u8 = null,
};
fn compareCardCounts(context: void, count1: CardCount, count2: CardCount) bool {
    _ = context;
    return count1.count > count2.count;
}
const CardCounter = struct {
    cards: [5]CardCount = [5]CardCount{ .{}, .{}, .{}, .{}, .{} },
    len: u3 = 0,

    fn init(cards: [5]u8) CardCounter {
        var counter = CardCounter{};
        for (cards) |value| {
            for (counter.cards, 0..) |card_count, idx| {
                if (card_count.card == value) {
                    counter.cards[idx].count += 1;
                    break;
                }
                if (card_count.card == null) {
                    counter.cards[idx].card = value;
                    counter.cards[idx].count = 1;
                    counter.len += 1;
                    break;
                }
            }
        }
        std.sort.insertion(CardCount, &counter.cards, {}, compareCardCounts);
        return counter;
    }
};
const Hand = struct {
    strength: Strength,
    strengthJoker: Strength,
    bid: Bid,
    cards: [5]u8,

    fn calculateStrength(self: *Hand, use_joker: bool) Strength {
        // 5 of a kind (7) > 4 of a kind > full house > three of a kind > two pair > one pair > high card
        var counted = CardCounter.init(self.cards);
        if (use_joker and counted.len > 1) {
            for (counted.cards, 0..) |card_count, idx| {
                if (card_count.card == 'J') {
                    counted.cards[idx].count = 0;
                    counted.len -= 1;
                    std.sort.insertion(CardCount, &counted.cards, {}, compareCardCounts);
                    counted.cards[0].count += card_count.count;
                    break;
                }
            }
        }
        if (counted.len == 1) return 7; // Five of a kind
        if (counted.len == 2) {
            if (counted.cards[0].count == 4) return 6; // Four of a kind
            if (counted.cards[0].count == 3 and counted.cards[1].count == 2) return 5; // Full house
        }
        if (counted.len == 3) {
            if (counted.cards[0].count == 3) return 4; // Three of a kind
            if (counted.cards[0].count == 2 and counted.cards[1].count == 2) return 3; // Two pair
        }
        if (counted.len == 4) return 2; // One pair
        return 1; // High card
    }
};

const cardsByStrength = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
const cardsByStrengthJoker = [_]u8{ 'J', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'Q', 'K', 'A' };
fn getCardStrength(ch: u8, slice: []const u8) u8 {
    return @intCast(std.mem.indexOfScalar(u8, slice, ch).?);
}
fn compareHands(context: void, hand1: Hand, hand2: Hand) bool {
    if (hand1.strength != hand2.strength) {
        return std.sort.asc(Strength)(context, hand1.strength, hand2.strength);
    }
    var compareIdx: HandSize = 0;
    while (compareIdx < 5) : (compareIdx += 1) {
        const val1 = getCardStrength(hand1.cards[compareIdx], &cardsByStrength);
        const val2 = getCardStrength(hand2.cards[compareIdx], &cardsByStrength);
        if (val1 < val2) return true;
        if (val1 > val2) return false;
    }
    return true;
}
fn compareHandsJoker(context: void, hand1: Hand, hand2: Hand) bool {
    if (hand1.strengthJoker != hand2.strengthJoker) {
        return std.sort.asc(Strength)(context, hand1.strengthJoker, hand2.strengthJoker);
    }
    var compareIdx: HandSize = 0;
    while (compareIdx < 5) : (compareIdx += 1) {
        const val1 = getCardStrength(hand1.cards[compareIdx], &cardsByStrengthJoker);
        const val2 = getCardStrength(hand2.cards[compareIdx], &cardsByStrengthJoker);
        if (val1 < val2) return true;
        if (val1 > val2) return false;
    }
    return true;
}

fn parseInput(input: [:0]const u8, out_hand_list: *ArrayList(Hand)) !void {
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, input_trimmed, '\n');
    var next_line = lines_iterator.next();
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        const hand = try out_hand_list.addOne();
        std.mem.copyForwards(u8, &hand.cards, line[0..5]);
        const parsed = try utils.parseNumberAtStart(Bid, line[6..]);
        hand.bid = parsed.value;
        hand.strength = hand.calculateStrength(false);
        hand.strengthJoker = hand.calculateStrength(true);
    }
}

pub fn solveStar1(hands: *ArrayList(Hand)) u64 {
    std.mem.sort(Hand, hands.items, {}, compareHands);
    var sum: u64 = 0;
    for (hands.items, 1..) |*hand, rank| {
        // std.debug.print("Rank {} hand {s}\n", .{ rank, hand.cards });
        sum += hand.bid * rank;
    }
    return sum;
}

pub fn solveStar2(hands: *ArrayList(Hand)) u64 {
    std.mem.sort(Hand, hands.items, {}, compareHandsJoker);
    var sum: u64 = 0;
    for (hands.items, 1..) |*hand, rank| {
        // std.debug.print("Rank {} hand {s}\n", .{ rank, hand.cards });
        sum += hand.bid * rank;
    }
    return sum;
}

pub fn main() !void {
    var hands = ArrayList(Hand).init(ga);
    try parseInput(full, &hands);

    const result1 = solveStar1(&hands);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&hands);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var hands = ArrayList(Hand).init(ga);
    try parseInput(simple, &hands);

    const result1 = solveStar1(&hands);
    try expect(result1 == 6440);
    const result2 = solveStar2(&hands);
    try expect(result2 == 5905);
}

test "full" {
    var hands = ArrayList(Hand).init(ga);
    try parseInput(full, &hands);

    const result1 = solveStar1(&hands);
    try expect(result1 == 249726565);
    const result2 = solveStar2(&hands);
    try expect(result2 == 251135960);
}
