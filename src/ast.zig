const std = @import("std");

pub const NodeList = std.MultiArrayList(Node);

pub const Value = union(enum) {
    BinaryOpration: u8,
    Integer: f64,
};

pub const Node = struct {
    value: Value,
    left: ?usize,
    right: ?usize,
};
