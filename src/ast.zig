const std = @import("std");
const Tok = @import("./token.zig");
const Loc = @import("./lexer.zig").Loc;

pub const NodeList = std.MultiArrayList(Node);

pub const Level = enum { err, waring };

pub const Error = struct {
    level: Level = .err,
    token: ?Tok.Token = null,
    message: []const u8,
    message_allocated: bool = false,
    loc: Loc = .init,
};

pub const Value = union(enum) {
    BinaryOperation: u8,
    Integer: f64,
};

pub const Node = struct {
    value: Value,
    left: ?usize,
    right: ?usize,
};
