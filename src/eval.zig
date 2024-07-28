const std = @import("std");
const parser = @import("./parser.zig");
const astStruct = @import("./ast.zig");

const AutoHashMap = std.AutoHashMap;
const MultiArrayList = std.MultiArrayList;
const Allocator = std.mem.Allocator;
const AstTree = astStruct.AstTree;
const AstListType = astStruct.AstListType;

pub const MapType = AutoHashMap(usize, f64);

pub const Eval = struct {
    const Self = @This();
    alloc: Allocator,
    map: MapType,
    ast: *MultiArrayList(AstTree),
    final: usize,

    pub fn init(ast: *MultiArrayList(AstTree), alloc: Allocator) Self {
        return .{
            .alloc = alloc,
            .map = MapType.init(alloc),
            .ast = ast,
            .final = 0,
        };
    }
    pub fn deinit(self: *Self) void {
        self.map.deinit();
    }
    fn nodeValue(self: *Self, key: usize) f64 {
        const num = switch (self.ast.get(key).value) {
            .BinaryOpration => self.map.get(key) orelse 0,
            .Integer => |n| return n,
        };
        return num;
    }
    fn leftVal(self: *Self, cur_node: *const AstTree) f64 {
        if (cur_node.left) |lhs| {
            return self.nodeValue(lhs);
        }
        return 0;
    }
    fn rightVal(self: *Self, cur_node: *const AstTree) f64 {
        if (cur_node.right) |rhs| {
            return self.nodeValue(rhs);
        }
        return 0;
    }

    fn perFormOpration(_: Self, op: u8, lhs_val: f64, rhs_val: f64) f64 {
        return switch (op) {
            '+' => lhs_val + rhs_val,
            '-' => lhs_val - rhs_val,
            '/' => lhs_val / rhs_val,
            '*' => lhs_val * rhs_val,
            else => 0,
        };
    }
    pub fn eval(self: *Self) !f64 {
        for (0..self.ast.len) |i| {
            const cur_node = self.ast.get(i);
            switch (cur_node.value) {
                .BinaryOpration => |op| {
                    const lhs_val: f64 = self.leftVal(&cur_node);
                    const rhs_val: f64 = self.rightVal(&cur_node);
                    const res = self.perFormOpration(op, lhs_val, rhs_val);
                    try self.map.put(i, res);
                    self.final = i;
                },
                else => {},
            }
        }
        return self.map.get(self.final) orelse 0;
    }
};
