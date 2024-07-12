const std = @import("std");
pub const Token = union(enum) {
    operator: u8,
    num: []const u8,
    function: []const u8,
    illegal: []const u8,

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

    pub fn init(input: []const u8) Self {
        var lex = Self{
            .input = input,
        };
        lex.readChar();
        return lex;
    }
    pub fn nextToke(self: *Self) Token {
        self.skipWhitespace();
        const tok: Token = switch (self.ch) {
            '{' => .lsquirly,
            '}' => .rsquirly,
            '(' => .lparen,
            ')' => .rparen,
            '<' => .less_than,
            '>' => .greater_than,
            // '=' => blk: {
            //     if (self.peek('=')) {
            //         self.readChar();
            //         break :blk .equal;
            //     } else {
            //         break :blk .assign;
            //     }
            // },
            // x + - / ^ for this operator.
            42, 43, 45, 47, 94 => .{ .operator = self.ch },
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
                return .{ .num = num };
            },
            else => {
                return .{ .illegal = "Hello " };
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

    fn peek(self: *Self, ch: u8) bool {
        return (self.input[self.read_position] == ch) and !(self.read_position >= self.input.len);
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
