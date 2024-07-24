const std = @import("std");
const lexer = @import("./lexer.zig");

const Lexer = lexer.Lexer;
const Token = lexer.Token;

const pretty = @import("pretty");
const alloc = std.heap.c_allocator;
const TokenError = error{
    NoTokenFound,
};

pub const AstTreeValue = union(enum) {
    BinaryOpration: u8,
    Integer: i64,
};

pub const AstTree = struct {
    value: ?AstTreeValue,
    left: ?*const AstTree,
    right: ?*const AstTree,
};

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,
    cur: Token,
    tree: *AstTree,

    fn token(self: Self) Token {
        return self.cur;
    }
    fn nextToken(self: *Self) !void {
        const tok = try self.lex.nextToke();
        self.cur = tok;
    }

    fn isTokenOp(self: Self, ch: u8) bool {
        return self.cur.isOprater(ch);
    }

    fn getNumFromToken(self: Self) ?i64 {
        return switch (self.cur) {
            .num => |n| n,
            else => null,
        };
    }

    fn hasToken(self: Self) bool {
        return self.lex.hasTokes();
    }

    pub fn init(lex: *Lexer) !Self {
        const lx = lex;
        const cur = try lx.nextToke();
        var tree = AstTree{ .value = null, .left = null, .right = null };
        return .{
            .lex = lx,
            .cur = cur,
            .tree = &tree,
        };
    }

    pub fn parse(self: *Self) !void {
        const a = try self.parseExpression();
        try pretty.print(alloc, a, .{
            .max_depth = 0,
            .struct_max_len = 0,
        });
    }

    fn parseExpression(self: *Self) !AstTree {
        var lhs = try self.parseTerm();
        while (self.isTokenOp('+') or self.isTokenOp('-')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs = try self.parseTerm();
            lhs = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = &lhs,
                .right = &rhs,
            };
        }
        return lhs;
    }
    fn parseTerm(self: *Self) !AstTree {
        var lhs = try self.parseFactor();
        while (self.isTokenOp('*') or self.isTokenOp('/')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs = try self.parseFactor();
            lhs = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = &lhs,
                .right = &rhs,
            };
        }
        return lhs;
    }
    fn parseFactor(self: *Self) !AstTree {
        if (self.getNumFromToken()) |num| {
            try self.nextToken();
            return AstTree{ .value = .{ .Integer = num }, .left = null, .right = null };
        }
        return TokenError.NoTokenFound;
    }
};
