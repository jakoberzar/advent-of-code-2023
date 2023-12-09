const std = @import("std");
const expect = std.testing.expect;
const isDigit = std.ascii.isDigit;
const ArrayList = std.ArrayList;

const utils = @import("utils.zig");

const day = "day-08";
const simple = @embedFile("./inputs/" ++ day ++ "/simple.txt");
const simple2 = @embedFile("./inputs/" ++ day ++ "/simple2.txt");
const simple3 = @embedFile("./inputs/" ++ day ++ "/simple3.txt");
const full = @embedFile("./inputs/" ++ day ++ "/full.txt");
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ga = arena.allocator();

const NodeRefType = u32;
const name_len = 3;
const NodeName = [name_len]u8;
const Node = struct {
    name: NodeName,
    left: NodeRefType,
    right: NodeRefType,
};

// TODO: Make it more general and part of utils, shared with at least day 6
fn skipToNext(input: []const u8, c: u8) usize {
    var char_idx: usize = 0;
    while (char_idx < input.len and input[char_idx] != c) : (char_idx += 1) {}
    return char_idx;
}

fn skipToNextSpace(input: []const u8) usize {
    return skipToNext(input, ' ');
}

fn parseInput(input: [:0]const u8, out_node_list: *ArrayList(Node), out_node_map: *std.StringHashMap(NodeRefType)) ![]const u8 {
    const inputTrimmed = std.mem.trimRight(u8, input, &[_]u8{ 0, '\n' });
    var lines_iterator = std.mem.splitScalar(u8, inputTrimmed, '\n');
    const instructions = lines_iterator.next().?;
    _ = lines_iterator.next().?; // Skip empty line
    var lines_iterator_copy = lines_iterator;

    // Populate the node map
    var next_line = lines_iterator.next();
    while (next_line != null) {
        const line = next_line.?;
        next_line = lines_iterator.next();

        // const node_name_end = skipToNextSpace(line);
        const node_title = line[0..name_len];
        try out_node_map.put(node_title, @intCast(out_node_list.items.len));
        const new_node = try out_node_list.addOne();
        std.mem.copyForwards(u8, &new_node.name, node_title);
    }

    // Wire the nodes
    next_line = lines_iterator_copy.next();
    var node_idx: NodeRefType = 0;
    while (next_line != null) : (node_idx += 1) {
        const line = next_line.?;
        next_line = lines_iterator_copy.next();

        const cur_node = &out_node_list.items[node_idx];
        const start_left = skipToNext(line, '(') + 1; // Skip parenthesis
        const end_left = start_left + skipToNext(line[start_left..], ',');
        const left_node = line[start_left..end_left];
        cur_node.left = out_node_map.get(left_node).?;

        const start_right = end_left + 2; // Skip comma and space
        const end_right = start_right + skipToNext(line[start_right..], ')');
        const right_node = line[start_right..end_right];
        cur_node.right = out_node_map.get(right_node).?;
    }

    return instructions;
}

pub fn solveStar1(nodes: *ArrayList(Node), instructions: []const u8, node_map: *std.StringHashMap(NodeRefType)) u64 {
    var moves: u64 = 0;
    var current_instruction: usize = 0;
    var current_node: NodeRefType = node_map.get("AAA").?;
    const final_node: NodeRefType = node_map.get("ZZZ").?;
    while (current_node != final_node) : (moves += 1) {
        const instruction = instructions[current_instruction];
        const node_entry = nodes.items[current_node];
        // std.debug.print("Current is {}=({},{}) instr is {}\n", .{ current_node, node_entry.left, node_entry.right, instruction });
        const next_node = switch (instruction) {
            'L' => node_entry.left,
            'R' => node_entry.right,
            else => {
                std.debug.print("Invalid instruction {}", .{instruction});
                return 0;
            },
        };
        current_node = next_node;
        current_instruction = (current_instruction + 1) % instructions.len;
    }
    return moves;
}

fn determineStartingNodes(node_map: *std.StringHashMap(NodeRefType), out_nodes: *ArrayList(NodeRefType)) !void {
    var node_iterator = node_map.iterator();
    var next_entry = node_iterator.next();
    while (next_entry != null) {
        const entry = next_entry.?;
        next_entry = node_iterator.next();
        if (entry.key_ptr.*[2] == 'A') {
            try out_nodes.append(entry.value_ptr.*);
        }
    }
}

const MoveSize = u63;
const InstrIdx = usize;
const CacheIdxValue = usize;
const NodeInstrPair = struct {
    node: NodeRefType,
    instr: InstrIdx,
    nodes_len: NodeRefType,
    // instr_len: usize,
    fn cacheIdxValue(self: *const NodeInstrPair) CacheIdxValue {
        return self.instr * self.nodes_len + self.node;
    }
    fn print(self: *const NodeInstrPair) void {
        std.debug.print("node {} instr {} idx {}", .{
            self.node,
            self.instr,
            self.cacheIdxValue(),
        });
    }
};
const NodeMoves = struct {
    pair: NodeInstrPair,
    moves: MoveSize,
    fn printLn(self: *const NodeMoves) void {
        self.pair.print();
        std.debug.print(" moves {}\n", .{self.moves});
    }
};
const CycleInfo = struct {
    cycle_start_node: NodeInstrPair,
    cycle_started: MoveSize,
    cycle_len: MoveSize,
    fn printLn(self: *const CycleInfo) void {
        std.debug.print("started at move {}, length {}, start ", .{
            self.cycle_started,
            self.cycle_len,
        });
        self.cycle_start_node.print();
        std.debug.print("\n", .{});
    }
};
const NodeState = struct {
    current_node: NodeMoves,
    visited: *ArrayList(?MoveSize),
    wins: ArrayList(NodeMoves),
    cycle: ?CycleInfo,
    starting_node: NodeInstrPair,

    // Static, here for reference
    nodes: *const ArrayList(Node),
    node_map: *const std.StringHashMap(NodeRefType),
    instr_len: usize,
    fn init(
        self: *NodeState,
        node: NodeRefType,
        nodes: *const ArrayList(Node),
        node_map: *const std.StringHashMap(NodeRefType),
        visited: *ArrayList(?MoveSize),
        instr_len: usize,
    ) !void {
        self.wins = ArrayList(NodeMoves).init(ga);
        self.cycle = null;
        self.current_node.moves = 0;
        self.current_node.pair.instr = 0;
        self.current_node.pair.node = node;
        self.current_node.pair.nodes_len = @intCast(nodes.items.len);
        self.starting_node = self.current_node.pair;
        self.nodes = nodes;
        self.node_map = node_map;
        self.visited = visited;
        self.instr_len = instr_len;
    }
    fn goNext(self: *NodeState, next_instruction: u8) !void {
        const node_entry = &self.nodes.items[self.current_node.pair.node];
        const cache_idx = self.current_node.pair.cacheIdxValue();
        // std.debug.print("Node starting {}, idx is {}\n", .{ self.starting_node.node, cache_idx });
        if (self.cycle == null) {
            if (self.visited.items[cache_idx] == null) {
                // Add to cache
                self.visited.items[cache_idx] = self.current_node.moves;
                if (node_entry.name[2] == 'Z') {
                    // Winning node
                    try self.wins.append(self.current_node);
                }
            } else {
                // Deja vu! I have seen this node before
                // Detect the cycle.
                const cycle_started = self.visited.items[cache_idx].?;
                self.cycle = CycleInfo{
                    .cycle_start_node = self.current_node.pair,
                    .cycle_started = cycle_started,
                    .cycle_len = self.current_node.moves - cycle_started,
                };
                std.debug.print("Deja vu! Cycle ", .{});
                self.cycle.?.printLn();
            }
        } else {
            // Already solved
            return;
        }
        // Calculate next
        const last_node = self.current_node;
        // std.debug.print("Current ", .{});
        // last_node.printLn();
        self.current_node.moves = last_node.moves + 1;
        self.current_node.pair.instr = (last_node.pair.instr + 1) % self.instr_len;
        self.current_node.pair.node = switch (next_instruction) {
            'L' => node_entry.left,
            'R' => node_entry.right,
            // TODO: Make it only two bits and an enum...
            else => {
                std.debug.print("Invalid instruction {}", .{next_instruction});
                return;
            },
        };
        // std.debug.print("New ", .{});
        // self.current_node.printLn();
        // std.debug.print("\n", .{});
    }
};

pub fn solveStar2States(nodes: *ArrayList(Node), instructions: []const u8, node_map: *std.StringHashMap(NodeRefType)) MoveSize {
    var current_instruction: usize = 0;
    var starting_nodes = ArrayList(NodeRefType).init(ga);
    determineStartingNodes(node_map, &starting_nodes) catch unreachable;
    var states = ArrayList(NodeState).init(ga);
    var visited = ArrayList(?MoveSize).init(ga);
    visited.appendNTimes(null, nodes.items.len * instructions.len) catch unreachable;
    for (starting_nodes.items) |node_ref| {
        var new_node = states.addOne() catch unreachable;
        new_node.init(node_ref, nodes, node_map, &visited, instructions.len) catch unreachable;
    }

    for (states.items) |*state| {
        var moves: MoveSize = 0;
        while (state.cycle == null) : (moves += 1) {
            const instruction = instructions[current_instruction];
            state.goNext(instruction) catch unreachable;
            current_instruction = (current_instruction + 1) % instructions.len;
        }
    }
    var lcm = utils.lcm(states.items[0].cycle.?.cycle_len, states.items[1].cycle.?.cycle_len);
    for (states.items, 0..) |*state, idx| {
        std.debug.print("State {}:", .{idx});
        state.cycle.?.printLn();
        for (state.wins.items) |win| {
            std.debug.print("Possible win ", .{});
            win.printLn();
        }
        lcm = utils.lcm(lcm, state.cycle.?.cycle_len);
    }
    return @intCast(lcm);
}

pub fn main() !void {
    var nodes = ArrayList(Node).init(ga);
    var node_map = std.StringHashMap(NodeRefType).init(ga);
    const instructions = try parseInput(full, &nodes, &node_map);

    const result1 = solveStar1(&nodes, instructions, &node_map);
    std.debug.print("Star 1 result is {}\n", .{result1});
    const result2 = solveStar2States(&nodes, instructions, &node_map);
    std.debug.print("Star 2 result is {}\n", .{result2});
}

test "simple" {
    var nodes = ArrayList(Node).init(ga);
    var node_map = std.StringHashMap(NodeRefType).init(ga);
    const instructions = try parseInput(simple, &nodes, &node_map);

    const result1 = solveStar1(&nodes, instructions, &node_map);
    try expect(result1 == 2);
}

test "simple 2" {
    var nodes = ArrayList(Node).init(ga);
    var node_map = std.StringHashMap(NodeRefType).init(ga);
    const instructions = try parseInput(simple2, &nodes, &node_map);

    const result1 = solveStar1(&nodes, instructions, &node_map);
    try expect(result1 == 6);
}

test "simple 3" {
    var nodes = ArrayList(Node).init(ga);
    var node_map = std.StringHashMap(NodeRefType).init(ga);
    const instructions = try parseInput(simple3, &nodes, &node_map);

    const result1 = solveStar2States(&nodes, instructions, &node_map);
    try expect(result1 == 6);
}

test "full" {
    var nodes = ArrayList(Node).init(ga);
    var node_map = std.StringHashMap(NodeRefType).init(ga);
    const instructions = try parseInput(full, &nodes, &node_map);

    const result1 = solveStar1(&nodes, instructions, &node_map);
    try expect(result1 == 17263);
    const result2 = solveStar2States(&nodes, instructions, &node_map);
    try expect(result2 == 14_631_604_759_649);
}
