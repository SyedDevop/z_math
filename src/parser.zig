const std = @import("std");
const lexer = @import("./lexer.zig");
const pretty = @import("pretty");
const Ast = @import("./ast.zig");
const ass = std.zig.Ast;
const Token = @import("./token.zig").Token;
const Allocator = std.mem.Allocator;
const Lexer = lexer.Lexer;

const TokenError = error{
    NoTokenFound,
} || Allocator.Error || std.fmt.ParseFloatError;

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,
    cur: Token,
    ast: Ast.NodeList,
    alloc: Allocator,

    fn token(self: Self) Token {
        return self.cur;
    }
    fn nextToken(self: *Self) TokenError!void {
        const tok = try self.lex.nextToke();

        self.cur = tok;
    }

    fn appendAst(self: *Self, ast: Ast.Node) TokenError!void {
        try self.ast.append(self.alloc, ast);
    }

    fn isTokenOp(self: Self, ch: u8) bool {
        return self.cur.isOprater(ch);
    }

    fn getNumFromToken(self: Self) ?f64 {
        return switch (self.cur) {
            .num => |n| n,
            else => null,
        };
    }

    fn hasToken(self: Self) bool {
        return self.lex.hasTokes();
    }

    fn isTerm(self: Self) bool {
        return self.isTokenOp('*') or
            self.isTokenOp('/') or
            self.isTokenOp('^') or
            self.isTokenOp('%') or
            self.isTokenOp('m');
    }
    pub fn init(lex: *Lexer, alloc: Allocator) !Self {
        const lx = lex;
        const cur = try lx.nextToke();
        return .{
            .lex = lx,
            .cur = cur,
            .ast = .{},
            .alloc = alloc,
        };
    }

    pub fn parse(self: *Self) !void {
        _ = try self.parseExpression();
    }

    pub fn deinit(self: *Self) void {
        self.ast.deinit(self.alloc);
    }
    fn parseExpression(self: *Self) TokenError!usize {
        var lhs_idx = try self.parseTerm();
        while (self.isTokenOp('+') or self.isTokenOp('-')) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs_idx = try self.parseTerm();
            const ast = Ast.Node{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = rhs_idx,
            };
            lhs_idx = self.ast.len;
            try self.appendAst(ast);
        }
        return lhs_idx;
    }
    fn parseTerm(self: *Self) TokenError!usize {
        var lhs_idx = try self.parseFactor();
        while (self.isTerm()) {
            const pre_op = self.token().operator;
            try self.nextToken();
            const rhs_idx = try self.parseFactor();
            const ast = Ast.Node{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = rhs_idx,
            };
            lhs_idx = self.ast.len;
            try self.appendAst(ast);
        }
        return lhs_idx;
    }
    fn parseFactor(self: *Self) TokenError!usize {
        return switch (self.token()) {
            .num => |num| {
                try self.nextToken();
                try self.appendAst(Ast.Node{ .value = .{ .Integer = num }, .left = null, .right = null });
                return self.ast.len - 1;
            },
            .lparen => {
                try self.nextToken();
                const expr = try self.parseExpression();
                try self.nextToken();
                return expr;
            },
            .eof => {
                std.debug.print("\x1b[33mWaring: The expression provided is too short. Please provide a longer or more detailed expression\x1b[0m", .{});
                std.process.exit(1);
            },
            else => {
                std.debug.panic("Illegal Tonken:: {any}", .{self.token()});
            },
        };
    }
};
