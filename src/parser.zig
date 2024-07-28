const std = @import("std");
const lexer = @import("./lexer.zig");
const pretty = @import("pretty");
const astStruct = @import("./ast.zig");

const Allocator = std.mem.Allocator;
const Lexer = lexer.Lexer;
const Token = lexer.Token;
const AstTree = astStruct.AstTree;
const AstListType = astStruct.AstListType;

const TokenError = error{
    NoTokenFound,
};

pub const Parser = struct {
    const Self = @This();
    lex: *Lexer,
    cur: Token,
    ast: AstListType,
    alloc: Allocator,

    fn token(self: Self) Token {
        return self.cur;
    }
    fn nextToken(self: *Self) void {
        const tok = self.lex.nextToke() catch |err| {
            std.debug.panic("Unable to get the next Toke.\n(err):: {any}", .{err});
        };
        self.cur = tok;
    }

    fn appendAst(self: *Self, ast: AstTree) void {
        self.ast.append(self.alloc, ast) catch |err| {
            std.debug.panic("Unable To add AstTree to map. \nTree:: {any} .\n(err):: {any}", .{ ast, err });
        };
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
            .ast = AstListType{},
            .alloc = alloc,
        };
    }

    pub fn parse(self: *Self) void {
        _ = self.parseExpression();
    }

    pub fn deinit(self: *Self) void {
        self.ast.deinit(self.alloc);
    }
    fn parseExpression(self: *Self) usize {
        var lhs_idx = self.parseTerm();
        while (self.isTokenOp('+') or self.isTokenOp('-')) {
            const pre_op = self.token().operator;
            self.nextToken();
            const rhs_idx = self.parseTerm();
            const ast = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = rhs_idx,
            };
            lhs_idx = self.ast.len;
            self.appendAst(ast);
        }
        return lhs_idx;
    }
    fn parseTerm(self: *Self) usize {
        var lhs_idx = self.parseFactor();
        while (self.isTerm()) {
            const pre_op = self.token().operator;
            self.nextToken();
            const rhs_idx = self.parseFactor();
            const ast = AstTree{
                .value = .{ .BinaryOpration = pre_op },
                .left = lhs_idx,
                .right = rhs_idx,
            };
            lhs_idx = self.ast.len;
            self.appendAst(ast);
        }
        return lhs_idx;
    }
    fn parseFactor(self: *Self) usize {
        return switch (self.token()) {
            .num => |num| {
                self.nextToken();
                self.appendAst(AstTree{ .value = .{ .Integer = num }, .left = null, .right = null });
                return self.ast.len - 1;
            },
            .lparen => {
                self.nextToken();
                const expr = self.parseExpression();
                self.nextToken();
                return expr;
            },
            else => {
                std.debug.panic("Illegal Tonken:: {any}", .{self.token()});
            },
        };
    }
};
