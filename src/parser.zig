const std = @import("std");
const lexer = @import("./lexer.zig");
const Ast = @import("./ast.zig");
const ass = std.zig.Ast;
const Token = @import("./token.zig").Token;
const Allocator = std.mem.Allocator;
const Lexer = lexer.Lexer;

const ZAppError = @import("./errors.zig").ZAppErrors;
const Error = Allocator.Error || std.fmt.ParseFloatError;

pub const Parser = struct {
    const Self = @This();

    input: []const u8,

    lex: *Lexer,
    cur: Token,
    ast: Ast.NodeList,

    alloc: Allocator,

    errors: std.ArrayListUnmanaged(Ast.Error),

    pub fn init(input: []const u8, lex: *Lexer, alloc: Allocator) !Self {
        const lx = lex;
        const cur = try lx.nextToke();
        return .{
            .lex = lx,
            .cur = cur,
            .input = input,
            .ast = .{},
            .alloc = alloc,
            .errors = .{},
        };
    }

    pub fn deinit(self: *Self) void {
        self.ast.deinit(self.alloc);
        self.errors.deinit(self.alloc);
    }

    fn token(self: Self) Token {
        return self.cur;
    }
    fn nextToken(self: *Self) Error!void {
        const tok = try self.lex.nextToke();

        self.cur = tok;
    }

    fn appendAst(self: *Self, ast: Ast.Node) Error!void {
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

    pub fn parse(self: *Self) !void {
        while (self.lex.hasTokes()) {
            _ = try self.parseExpression();
        }
        if (self.ast.len == 1) {
            try self.errors.append(self.alloc, .{ .message = "Incomplete expression: Missing operator after the number." });
        }
    }
    pub fn evaluate_errors(self: Self, input: []const u8) !void {
        if (self.errors.items.len == 0) return;
        for (self.errors.items) |err| {
            if (err.level == .err) {
                std.debug.print("The input is :: {s} ::\n\x1b[0m", .{input});
                std.debug.print("\x1b[31mError: {s}\x1b[0m\n", .{err.message});
            } else {
                std.debug.print("\x1b[33mWaring: {s}\x1b[0m\n", .{err.message});
            }
            if (err.token) |tok| {
                std.debug.print("\x1b[33mToke:: {any}\x1b[0m\n", .{tok});
            }
            if (err.message_alloced) {
                self.alloc.free(err.message);
            }
        }
        return ZAppError.exit;
    }
    fn parseExpression(self: *Self) Error!usize {
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
    fn parseTerm(self: *Self) Error!usize {
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
    fn parseFactor(self: *Self) Error!usize {
        // std.debug.print("Cur Token is {any}\n", .{self.token()});
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
                std.debug.print("Ast len {d}\n", .{self.ast.len});
                if (self.ast.len == 1) {
                    try self.errors.append(self.alloc, .{ .message = "Incomplete expression: Missing second operand after the operator." });
                    return 0;
                }
                try self.errors.append(self.alloc, .{ .message = "The expression provided is too short. Please provide a longer or more detailed expression", .level = .waring });
                return 0;
            },
            .illegal => |il| {
                try self.nextToken();
                var s = std.ArrayList(u8).init(self.alloc);
                defer s.deinit();

                // 16 is the prefix for the input print at start.
                for (il.st_pos + 9) |_| {
                    try s.append(' ');
                }

                if (il.st_pos != il.en_pos) {
                    for ((il.en_pos - il.st_pos) - 1) |_| {
                        try s.append('^');
                    }
                }

                try s.appendSlice("^ Found illegal character");
                const mess = try s.toOwnedSlice();
                try self.errors.append(self.alloc, .{ .message_alloced = true, .message = mess });
                return 0;
            },
            else => {
                try self.nextToken();
                try self.errors.append(self.alloc, .{ .message = " Illegal Tonken:: ", .token = self.token() });
                return 0;
            },
        };
    }
};
