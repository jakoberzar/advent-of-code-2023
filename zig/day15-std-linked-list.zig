const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-15";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const Operation = enum { remove, set };
const LabelLen = u8;
const FocalLen = u4;
const Step = struct {
    operation: Operation,
    operand: ?FocalLen = null,
    label_len: LabelLen,
    text: []const u8,
    fn getLabel(self: *Step) []const u8 {
        return self.text[0..self.label_len];
    }
};
const Lens = struct {
    focal: FocalLen,
    label: []const u8,
};
const LensList = std.DoublyLinkedList(Lens);
const LensNodePtr = *LensList.Node;
const Box = struct {
    list: LensList,
    fn focusingPower(self: *Box, box_idx: u8) u64 {
        const box_val = @as(u32, box_idx) + 1;
        var sum: u64 = 0;
        var slot: u32 = 1;
        var current = self.list.first;
        while (current) |current_ptr| : (slot += 1) {
            sum += box_val * slot * current_ptr.data.focal;
            current = current_ptr.next;
        }
        return sum;
    }
    fn printBox(self: *Box, idx: ?usize) void {
        std.debug.print("Box {?}: ", .{idx});
        var current = self.list.first;
        while (current) |current_ptr| {
            std.debug.print(" [{s} {d}]", .{ current_ptr.data.label, current_ptr.data.focal });
            current = current_ptr.next;
        }
        std.debug.print("\n", .{});
    }
};
const BoxOrganizer = struct {
    boxes: [256]Box,
    allocator: std.mem.Allocator,
    reuse_nodes: ArrayList(LensNodePtr),
    fn init(allocator: std.mem.Allocator) BoxOrganizer {
        return BoxOrganizer{
            .boxes = [_]Box{.{ .list = .{} }} ** 256,
            .allocator = allocator,
            .reuse_nodes = ArrayList(LensNodePtr).init(allocator),
        };
    }
    fn findNode(box: *Box, label: []const u8) ?LensNodePtr {
        var current = box.list.first;
        while (current) |ptr| {
            if (std.mem.eql(u8, ptr.data.label, label)) {
                return ptr;
            }
            current = ptr.next;
        }
        return null;
    }
    fn processStep(self: *BoxOrganizer, step: *Step) void {
        const label = step.getLabel();
        const hash = calculateHash(label);
        const box = &self.boxes[hash];
        const node_opt = findNode(box, label);
        switch (step.operation) {
            Operation.remove => {
                if (node_opt) |node| {
                    box.list.remove(node);
                    // Store node to reuse later
                    node.next = null;
                    self.reuse_nodes.append(node) catch unreachable;
                }
            },
            Operation.set => {
                if (node_opt) |node| {
                    node.data.focal = step.operand.?;
                } else {
                    // Insert a new node
                    const new_node: LensNodePtr =
                        if (self.reuse_nodes.items.len > 0) self.reuse_nodes.pop() else self.allocator.create(LensList.Node) catch unreachable;
                    new_node.data.focal = step.operand.?;
                    new_node.data.label = label;
                    box.list.append(new_node);
                }
            },
        }
    }
    fn getFocusingPowerSum(self: *BoxOrganizer) u64 {
        var sum: u64 = 0;
        for (&self.boxes, 0..) |*box, idx| {
            sum += box.focusingPower(@intCast(idx));
        }
        return sum;
    }
};

fn parseStep(step_text: []const u8) Step {
    const last_char_idx = step_text.len - 1;
    const last_char = step_text[last_char_idx];
    if (last_char == '-') {
        return Step{
            .operation = Operation.remove,
            .label_len = @intCast(last_char_idx),
            .text = step_text,
        };
    } else {
        return Step{
            .operation = Operation.set,
            .operand = @intCast(last_char - '0'),
            .label_len = @intCast(last_char_idx - 1),
            .text = step_text,
        };
    }
}

fn parseInput(input: [:0]const u8, out_steps: *ArrayList(Step)) !void {
    const input_trimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var steps_iterator = std.mem.splitScalar(u8, input_trimmed, ',');
    var next_step = steps_iterator.next();
    while (next_step != null) {
        const step_text = next_step.?;
        next_step = steps_iterator.next();
        try out_steps.append(parseStep(step_text));
    }
}

fn calculateHash(text: []const u8) u8 {
    var current: u32 = 0;
    for (text) |char| {
        current += char;
        current *= 17;
        current &= 0xFF;
    }
    return @intCast(current);
}

pub fn solveStar1(steps: *ArrayList(Step)) u64 {
    var sum: u64 = 0;
    for (steps.items) |*step| {
        sum += calculateHash(step.text);
    }
    return sum;
}

pub fn solveStar2(steps: *ArrayList(Step)) u64 {
    var box_organizer = ga.create(BoxOrganizer) catch unreachable;
    box_organizer.* = BoxOrganizer.init(ga);
    for (steps.items) |*step| {
        box_organizer.processStep(step);
    }
    return box_organizer.getFocusingPowerSum();
}

pub fn main() !void {
    var steps = ArrayList(Step).init(ga);
    try parseInput(full, &steps);

    const result1 = solveStar1(&steps);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2(&steps);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var steps = ArrayList(Step).init(ga);
    try parseInput(simple, &steps);

    const result1 = solveStar1(&steps);
    try expect(result1 == 1320);
    const result2 = solveStar2(&steps);
    try expect(result2 == 145);
}

test "full" {
    var steps = ArrayList(Step).init(ga);
    try parseInput(full, &steps);

    const result1 = solveStar1(&steps);
    try expect(result1 == 497373);
    const result2 = solveStar2(&steps);
    try expect(result2 == 259356);
}
