const std = @import("std");
const lexer = @import("./lexer.zig");

const Lexer = lexer.Lexer;
const Token = lexer.Token;

const TokenError = error{
    NoTokenFound,
};

pub const Node = struct {
    type: []const u8,
    operator: ?u8,
    left: *AstTree,
    right: *AstTree,
};

pub const AstTree = struct {
    value: ?i64,
    node: ?*Node,
};

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,
    cur: Token,

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
        return .{
            .lex = lx,
            .cur = cur,
        };
    }

    pub fn parse(self: *Self) !AstTree {
        return try self.parseExpression();
    }

    fn parseExpression(self: *Self) !AstTree {
        var lhs = try self.parseTerm();
        while (self.isTokenOp('+') or self.isTokenOp('-')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            var rhs = try self.parseTerm();
            var nod = Node{ .type = "BinaryOpration", .operator = pre_op, .left = &lhs, .right = &rhs };
            lhs = AstTree{ .value = null, .node = &nod };
        }
        return lhs;
    }
    fn parseTerm(self: *Self) !AstTree {
        var lhs = try self.parseFactor();
        while (self.isTokenOp('*') or self.isTokenOp('/')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            var rhs = try self.parseFactor();
            var nod = Node{ .type = "BinaryOpration", .operator = pre_op, .left = &lhs, .right = &rhs };
            lhs = AstTree{ .value = null, .node = &nod };
        }
        return lhs;
    }
    fn parseFactor(self: *Self) !AstTree {
        if (self.getNumFromToken()) |num| {
            try self.nextToken();
            const literal = AstTree{ .value = num, .node = null };
            return literal;
        }
        return TokenError.NoTokenFound;
    }
};
