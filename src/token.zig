const std = @import("std");

pub const Token = union(enum) {
    num: f64,
    operator: u8,
    function: []const u8,

    illegal: struct {
        st_pos: usize,
        en_pos: usize,
    },

    // add,
    // sub,
    // mul,
    // div,
    // negate: u8,
    // id: u8,

    word: []const u8,

    colon,
    lparen,
    rparen,
    lsquirly,
    rsquirly,

    less_than,
    greater_than,

    equal,
    not_equal,

    eof,

    pub fn keyword(key: []const u8) ?Token {
        const map = std.StaticStringMap(Token).initComptime(.{
            .{ "tan", Token{ .function = "tan" } },
            .{ "sine", Token{ .function = "sine" } },
            .{ "cost", Token{ .function = "cost" } },
        });
        return map.get(key);
    }

    pub fn isOprater(self: Token, ch: u8) bool {
        return switch (self) {
            .operator => |op| ch == op,
            else => false,
        };
    }
};

pub fn displayToken(tok: Token) []const u8 {
    return switch (tok) {
        .num => "Number",
        .operator => "Operator",
        .function => "Function",
        .illegal => "Illegal",
        .word => "Word",
        .colon => ":",
        .lparen => "(",
        .rparen => ")",
        .lsquirly => "{",
        .rsquirly => "}",
        .less_than => "<",
        .greater_than => ">",
        .equal => "=",
        .not_equal => "!=",
        .eof => "EOF",
    };
}

test "Token" {
    std.debug.print("{s}", .{displayToken(Token.equal)});
}
