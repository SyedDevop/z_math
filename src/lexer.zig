const std = @import("std");
pub const Token = union(enum) {
    num: f64,
    operator: u8,
    function: []const u8,
    illegal: []const u8,

    // add,
    // sub,
    // mul,
    // div,
    // negate: u8,
    // id: u8,

    lparen,
    rparen,
    lsquirly,
    rsquirly,

    less_than,
    greater_than,

    equal,
    not_equal,

    eof,
    fn keyword(key: []const u8) ?Token {
        const map = std.StaticStringMap(Token).initComptime(.{
            .{ "tan", .{ .function = "tan" } },
            .{ "sine", .{ .function = "sine" } },
            .{ "cost", .{ .function = "cost" } },
        });
        return map.get(key);
    }

    pub fn toString(self: Token, writer: anytype) !void {
        switch (self) {
            .num => |n| {
                try std.fmt.formatInt(n, 10, std.fmt.Case.lower, .{}, writer);
            },
            .operator => |o| try std.fmt.format(writer, "{c}", .{o}),

            .lparen => try std.fmt.format(writer, "(", .{}),
            .rparen => try std.fmt.format(writer, ")", .{}),
            else => {},
        }
    }
    pub fn getCharNum(self: Token) ?f64 {
        return switch (self) {
            .num => |n| n,
            else => null,
        };
    }
    pub fn getCharOprater(self: Token) ?u8 {
        return switch (self) {
            .operator => |o| o,
            else => null,
        };
    }
    pub fn isOprater(self: Token, ch: u8) bool {
        return switch (self) {
            .operator => |op| ch == op,
            else => false,
        };
    }

    pub fn arryToString(tokens: []Token) ![]const u8 {
        var list = std.ArrayList(u8).init(std.heap.page_allocator);
        defer list.deinit();

        for (tokens) |tok| {
            try tok.toString(list.writer());
            try list.appendSlice(" ");
        }
        return try list.toOwnedSlice();
    }
};
fn isLetter(ch: u8) bool {
    return std.ascii.isAlphabetic(ch);
}
fn isNum(ch: u8) bool {
    return std.ascii.isDigit(ch);
}
fn isOprater(ch: u8) bool {
    return ch == '/' or ch == '*' or ch == '-' or ch == '+' or ch == '^';
}

pub const Lexer = struct {
    const Self = @This();
    read_position: usize = 0,
    position: usize = 0,
    ch: u8 = 0,
    input: []const u8,
    buf: [1020]u8 = undefined,

    pub fn init(input: []const u8) Self {
        var lex = Self{
            .input = input,
        };
        lex.readChar();
        return lex;
    }
    fn illegalTokenError(self: *Self) !void {
        _ = try std.fmt.bufPrint(&self.buf,
            \\the in put is ::{s}::
            \\@ the index of {d} is a illegal {c}
            \\
        , .{ self.input, self.position, self.input[self.position] });
    }
    pub fn nextToke(self: *Self) !Token {
        self.skipWhitespace();
        const tok: Token = switch (self.ch) {
            '{' => .lsquirly,
            '}' => .rsquirly,
            '(' => .lparen,
            ')' => .rparen,
            '<' => .less_than,
            '>' => .greater_than,
            '%' => blk: {
                if (self.peek('%')) {
                    self.readChar();
                    break :blk .{ .operator = 'm' };
                } else {
                    break :blk .{ .operator = self.ch };
                }
            },
            // x +  / ^ for this operator.
            42, 43, 47, 94 => .{ .operator = self.ch },
            // -
            45 => blk: {
                if (self.peekIsNum()) {
                    self.readChar();
                    const num = try std.fmt.parseFloat(f64, self.readNum());
                    break :blk .{ .num = -num };
                } else {
                    break :blk .{ .operator = self.ch };
                }
            },
            0 => .eof,
            'a'...'z', 'A'...'Z' => {
                const ident = self.readIdentifier();
                if (Token.keyword(ident)) |token| {
                    return token;
                }
                return .{ .illegal = "Idont know" };
            },
            '0'...'9' => {
                const num = self.readNum();
                return .{ .num = try std.fmt.parseFloat(f64, num) };
            },
            else => {
                self.illegalTokenError() catch return .{ .illegal = "unable to  Writing illegalTokenError" };
                return .{ .illegal = &self.buf };
            },
        };

        self.readChar();
        return tok;
    }
    fn readIdentifier(self: *Self) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) {
            self.readChar();
        }
        return self.input[position..self.position];
    }
    fn readNum(self: *Self) []const u8 {
        const startPos = self.position;
        while (isNum(self.ch)) {
            self.readChar();
        }
        return self.input[startPos..self.position];
    }

    pub fn peek(self: *Self, ch: u8) bool {
        return (self.input[self.read_position] == ch) and !(self.read_position >= self.input.len);
    }
    fn peekIsNum(self: *Self) bool {
        return isNum(self.input[self.read_position]);
    }
    fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }
    fn skipWhitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
    }
    pub fn hasTokes(self: *Self) bool {
        return self.ch != 0;
    }
};
