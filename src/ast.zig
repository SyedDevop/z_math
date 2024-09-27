const std = @import("std");
const Tok = @import("./token.zig");

pub const NodeList = std.MultiArrayList(Node);

pub const Level = enum { err, waring };

pub const Error = struct {
    level: Level = .err,
    token: ?Tok.Token = null,
    message: []const u8,
    message_alloced: bool = false,
};

pub const Value = union(enum) {
    BinaryOpration: u8,
    Integer: f64,
};

pub const Node = struct {
    value: Value,
    left: ?usize,
    right: ?usize,
};
