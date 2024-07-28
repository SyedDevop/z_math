const std = @import("std");

pub const AstListType = std.MultiArrayList(AstTree);

pub const AstTreeValue = union(enum) {
    BinaryOpration: u8,
    Integer: f64,
};

pub const AstTree = struct {
    value: AstTreeValue,
    left: ?usize,
    right: ?usize,
};
