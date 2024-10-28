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

pub const Lexer = struct {
    const Self = @This();
    read_position: usize = 0,
    position: usize = 0,
    ch: u8 = 0,
    input: []const u8,
    alloc: Allocator,

    pub fn init(input: []const u8, alloc: Allocator) Self {
        var lex = Self{
            .input = input,
            .alloc = alloc,
        };
        lex.readChar();
        return lex;
    }
    pub fn nextToke(self: *Self) std.fmt.ParseFloatError!Token {
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
                const cur_pos = self.position;
                const ident = self.readIdentifier();
                if (Token.keyword(ident)) |token| {
                    return token;
                }
                break :blk .{
                    .illegal = .{
                        .st_pos = cur_pos,
                        .en_pos = self.position,
                    },
                };
            },
            '0'...'9' => {
                const num = self.readNum();
                return .{ .num = try std.fmt.parseFloat(f64, num) };
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
    fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
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
        while (isNum(self.ch) or self.ch == '.' or self.ch == '_') {
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
    fn skipWhitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
    }
    pub fn hasTokes(self: *Self) bool {
        return self.ch != 0;
    }
};
