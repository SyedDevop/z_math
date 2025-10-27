const std = @import("std");

const Allocator = std.mem.Allocator;
const Token = @import("./token.zig").Token;

fn isLetter(ch: u8) bool {
    return std.ascii.isAlphabetic(ch);
}
fn isNum(ch: u8) bool {
    return std.ascii.isDigit(ch);
}
fn isOprater(ch: u8) bool {
    return ch == '/' or ch == '*' or ch == '-' or ch == '+' or ch == '^';
}

pub const Loc = struct {
    line_number: u32 = 0,
    line_offset: u32 = 0,
    pub const init: Loc = .{};
};

const Lexer = @This();
read_position: usize = 0,
position: usize = 0,
ch: u8 = 0,
input: []const u8,
alloc: Allocator,
line_number: u32 = 0,
line_offset: u32 = 0,

pub fn init(input: []const u8, alloc: Allocator) Lexer {
    var lex = Lexer{
        .input = input,
        .alloc = alloc,
    };
    lex.readChar();
    return lex;
}

pub fn nextToke(self: *Lexer) std.fmt.ParseFloatError!Token {
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
        ':' => .colon,
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
        'a'...'z', 'A'...'Z' => blk: {
            // const cur_pos = self.position;
            const ident = self.readIdentifier();
            if (Token.keyword(ident)) |token| {
                return token;
            }
            break :blk .{ .word = ident };
        },
        '0'...'9' => {
            const num = self.readNum();
            return .{ .num = try std.fmt.parseFloat(f64, num) };
        },
        '\n' => blk: {
            self.line_number += 1;
            self.line_offset = 0;
            break :blk .new_line;
        },

        else => .{
            .illegal = .{
                .st_pos = self.position,
                .en_pos = self.position,
            },
        },
    };

    self.readChar();
    return tok;
}

fn readChar(self: *Lexer) void {
    if (self.read_position >= self.input.len) {
        self.ch = 0;
    } else {
        self.ch = self.input[self.read_position];
    }

    self.position = self.read_position;
    self.line_offset += 1;
    self.read_position += 1;
}

fn readIdentifier(self: *Lexer) []const u8 {
    const position = self.position;
    while (isLetter(self.ch)) {
        self.readChar();
    }
    return self.input[position..self.position];
}

fn readNum(self: *Lexer) []const u8 {
    const startPos = self.position;
    while (isNum(self.ch) or self.ch == '.' or self.ch == '_') {
        self.readChar();
    }
    return self.input[startPos..self.position];
}

pub fn peek(self: *Lexer, ch: u8) bool {
    return (self.input[self.read_position] == ch) and !(self.read_position >= self.input.len);
}

fn peekIsNum(self: *Lexer) bool {
    return isNum(self.input[self.read_position]);
}

/// Returns whether this character is included in `whitespace`.
pub fn isWhitespace(c: u8) bool {
    return switch (c) {
        ' ', '\t', '\r' => true,
        else => false,
    };
}

fn skipWhitespace(self: *Lexer) void {
    while (isWhitespace(self.ch)) {
        self.readChar();
    }
}

pub fn hasTokes(self: *Lexer) bool {
    return self.ch != 0;
}

const TestLexer = struct {
    input: []const u8,
    output: []const Token,
};

const assert = std.debug.assert;
const eq = std.testing.expectEqual;
const eqd = std.testing.expectEqualDeep;

test "(Lexer) One Line" {
    const allocator = std.testing.allocator;
    const testLexer = TestLexer{
        .input = "50 + 50",
        .output = &.{
            .{ .num = 50 },
            .{ .operator = '+' },
            .{ .num = 50 },
            .eof,
        },
    };
    var lexer = Lexer.init(testLexer.input, allocator);
    for (0..testLexer.output.len) |i| {
        const tok = try lexer.nextToke();
        try eq(testLexer.output[i], tok);
    }
    try eq(false, lexer.hasTokes());
}

test "(Lexer) Multi Line" {
    const allocator = std.testing.allocator;
    const testLexer = TestLexer{
        .input =
        \\50 + 50
        \\50 + 50
        ,
        .output = &.{
            .{ .num = 50 },
            .{ .operator = '+' },
            .{ .num = 50 },
            .new_line,
            .{ .num = 50 },
            .{ .operator = '+' },
            .{ .num = 50 },
            .eof,
        },
    };
    var lexer = Lexer.init(testLexer.input, allocator);
    for (0..testLexer.output.len) |i| {
        const tok = try lexer.nextToke();
        try eq(testLexer.output[i], tok);
        if (tok == .new_line) try eq(1, lexer.line_number);
    }
    try eq(false, lexer.hasTokes());
}
