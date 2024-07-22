const std = @import("std");
const lexer = @import("./lexer.zig");

const Lexer = lexer.Lexer;
const Token = lexer.Token;

pub const Node = struct {
    type: []const u8,
    operator: ?u8,
    left: *AstTree,
    right: *AstTree,
};

pub const AstTree = union(enum) {
    value: i64,
    node: *const Node,
};

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,

    pub fn init(lex: *Lexer) Self {
        return .{
            .lex = lex,
        };
    }

    pub fn parse(self: *Self) !AstTree {
        var tree = AstTree{ .value = 0 };
        while (self.lex.hasTokes()) {
            const tok = try self.lex.nextToke();
            tree = try self.parseExpression(tok);
            // _ = try self.parseExpression(tok);
        }
        return tree;
    }

    fn parseExpression(self: *Self, tok: Token) !AstTree {
        var lhs = try self.parseTerm(tok);
        while (self.lex.hasTokes()) {
            while (self.lex.peek('-') or self.lex.peek('+')) {
                const opToken = try self.lex.nextToke();
                var rhs = try self.parseTerm(try self.lex.nextToke());
                lhs = AstTree{ .node = &Node{ .type = "BinaryOpration", .operator = opToken.operator, .left = &lhs, .right = &rhs } };
            }
        }
        return lhs;
    }
    fn parseTerm(self: *Self, tok: Token) !AstTree {
        var lhs = try self.parseFactor(tok);
        if (tok.getCharOprater()) |op| {
            while (op == '/' or op == '*') {
                var rhs = try self.parseFactor(tok);
                lhs = AstTree{ .node = &Node{ .type = "BinaryOpration", .operator = op, .left = &lhs, .right = &rhs } };
            }
        }
        return lhs;
    }
    fn parseFactor(_: *Self, tok: Token) !AstTree {
        if (tok.getCharNum()) |num| {
            return .{ .value = num };
        }
        std.debug.print("{any}", .{tok});
        return .{ .value = 0 };
    }
};
