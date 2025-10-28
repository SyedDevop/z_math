const std = @import("std");
const Allocator = std.mem.Allocator;

const Zarg = @import("zarg");
const Style = Zarg.Style;
const Color = Zarg.Style.Color;

const Ast = @import("./ast.zig");

const Token = @import("./token.zig").Token;

const Lexer = @import("./lexer.zig");

const ZAppError = @import("./errors.zig").ZAppErrors;
const Error = Allocator.Error || std.fmt.ParseFloatError || std.Io.Writer.Error;

pub const Parser = struct {
    const Self = @This();

    input: []const u8,

    lex: *Lexer,
    cur: Token,
    pre: Token,
    ast: Ast.NodeList,

    alloc: Allocator,

    errors: std.ArrayList(Ast.Error),

    pub fn init(input: []const u8, lex: *Lexer, alloc: Allocator) !Self {
        const lx = lex;
        const cur = try lx.nextToke();
        return .{
            .lex = lx,
            .cur = cur,
            .pre = cur,
            .input = input,
            .ast = .{},
            .alloc = alloc,
            .errors = .empty,
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
        self.pre = self.cur;
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

    inline fn location(self: Self) Lexer.Loc {
        return .{ .line_number = self.lex.line_number, .line_offset = self.lex.line_offset };
    }

    fn errorMessage(self: Self, message: []const u8, level: ?Ast.Level) Ast.Error {
        return Ast.Error{
            .message = message,
            .loc = self.location(),
            .level = level orelse .err,
        };
    }

    pub fn parse(self: *Self) !void {
        while (self.lex.hasTokes()) {
            _ = try self.parseExpression();
        }
        if (self.ast.len == 1) {
            try self.errors.append(self.alloc, self.errorMessage("Incomplete expression: Missing operator after the number.", null));
        }
    }

    pub fn evaluate_errors(self: Self, input: []const u8) !void {
        if (self.errors.items.len == 0) return;
        var buf: [256]u8 = undefined;
        const stderr = std.debug.lockStderrWriter(&buf);
        defer std.debug.unlockStderrWriter();
        for (self.errors.items) |err| {
            try stderr.print("The input is :: {s} ::\n", .{input});
            const errorType = if (err.level == .err) "✘ Error " else "⚠ Waring"; // try stderr.print("\x1b[31mError: {s}\x1b[0m\n", .{err.message});
            try Color.renderFmt(
                "{s}: {s}",
                .{ errorType, err.message },
                if (err.level == .err) .toAnsi8(197) else .toAnsi8(226),
                null,
                stderr,
            );
            if (err.token) |tok| {
                try stderr.writeAll("\x1b[38;5;226m");
                try tok.tokenValue("", stderr);
            }
            try stderr.writeAll("\x1b[0m\n");
            if (err.message_allocated) {
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
                .value = .{ .BinaryOperation = pre_op },
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
                .value = .{ .BinaryOperation = pre_op },
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
                if (self.lex.peek(')')) {
                    try self.nextToken();
                    return expr;
                }

                try self.errors.append(
                    self.alloc,
                    self.errorMessage("Incomplete expression: Missing closing parenthesis ", null),
                );
                return 0;
            },
            .eof => {
                std.debug.print("Ast len {d}\n", .{self.ast.len});
                if (self.ast.len == 1) {
                    try self.errors.append(
                        self.alloc,
                        self.errorMessage("Incomplete expression: Missing second operand after the operator.", null),
                    );
                    return 0;
                }
                try self.errors.append(
                    self.alloc,
                    self.errorMessage("The expression provided is too short. Please provide a longer or more detailed expression", .waring),
                );
                return 0;
            },
            .illegal => |il| {
                try self.nextToken();
                var s = std.ArrayList(u8).empty;
                defer s.deinit(self.alloc);

                // 9 is the prefix for the input print at start.
                for (0..il.st_pos + 6) |_| {
                    try s.append(self.alloc, ' ');
                }

                if (il.st_pos != il.en_pos) {
                    for (0..(il.en_pos - il.st_pos) - 1) |_| {
                        try s.append(self.alloc, '^');
                    }
                }

                try s.appendSlice(self.alloc, "^ Found illegal character");
                const mess = try s.toOwnedSlice(self.alloc);
                try self.errors.append(self.alloc, .{
                    .message_allocated = true,
                    .message = mess,
                    .loc = self.location(),
                });
                return 0;
            },
            else => {
                try self.errors.append(self.alloc, .{
                    .message = "Unexpected symbol:: ",
                    .token = self.token(),
                    .loc = self.location(),
                });
                try self.nextToken();
                return 0;
            },
        };
    }
};
