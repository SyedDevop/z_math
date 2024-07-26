const std = @import("std");
const lexer = @import("./lexer.zig");
const pretty = @import("pretty");

const Allocator = std.mem.Allocator;
const Lexer = lexer.Lexer;
const Token = lexer.Token;

const TokenError = error{
    NoTokenFound,
};

pub const AstTreeValue = union(enum) {
    BinaryOpration: u8,
    Integer: i64,
};

pub const AstTree = struct {
    value: ?AstTreeValue,
    left: ?usize,
    right: ?usize,
};

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,
    cur: Token,
    ast: std.MultiArrayList(AstTree),
    alloc: Allocator,

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

    pub fn init(lex: *Lexer, alloc: Allocator) !Self {
        const lx = lex;
        const cur = try lx.nextToke();
        return .{
            .lex = lx,
            .cur = cur,
            .ast = std.MultiArrayList(AstTree){},
            .alloc = alloc,
        };
    }

    pub fn parse(self: *Self) !void {
        _ = try self.parseExpression();
        for (0..self.ast.len) |i| {
            std.debug.print("{any}\n", .{self.ast.get(i)});
        }
    }

    pub fn deinit(self: *Self) void {
        self.ast.deinit(self.alloc);
    }
    fn parseExpression(self: *Self) !usize {
        var lhs_idx = try self.parseTerm();
        while (self.isTokenOp('+') or self.isTokenOp('-')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs_idx = try self.parseTerm();
            const ast = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = self.ast.len - 1,
            };
            lhs_idx = rhs_idx;
            try self.ast.append(self.alloc, ast);
        }
        return lhs_idx;
    }
    fn parseTerm(self: *Self) !usize {
        var lhs_idx = try self.parseFactor();
        while (self.isTokenOp('*') or self.isTokenOp('/')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs_idx = try self.parseFactor();
            const ast = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = self.ast.len - 1,
            };
            lhs_idx = rhs_idx;
            try self.ast.append(self.alloc, ast);
        }
        return lhs_idx;
    }
    fn parseFactor(self: *Self) !usize {
        return switch (self.token()) {
            .num => |num| {
                try self.nextToken();
                try self.ast.append(self.alloc, AstTree{ .value = .{ .Integer = num }, .left = null, .right = null });
                return self.ast.len - 1;
            },
            else => TokenError.NoTokenFound,
        };
    }
};
