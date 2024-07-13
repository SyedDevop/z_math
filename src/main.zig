const std = @import("std");
const lexer = @import("./lexer.zig");
// 3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3
//  3 4 2 * 1 5 - 2 3 ^ ^ / +

const print = std.debug.print;
const Lexer = lexer.Lexer;
const Token = lexer.Token;

pub fn main() !void {}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
// test "Parse to RPM" {
//     try testRpm("3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3", "342*15-23^^/+");
// }

const ex = std.testing.expectEqualDeep;
test "Lexer" {
    var lex = Lexer.init("3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3");
    const tokens = [_]Token{
        .{ .num = "3" },
        .{ .operator = '+' },
        .{ .num = "4" },
        .{ .operator = '*' },
        .{ .num = "2" },
        .{ .operator = '/' },
        .lparen,
        .{ .num = "1" },
        .{ .operator = '-' },
        .{ .num = "5" },
        .rparen,
        .{ .operator = '^' },
        .{ .num = "2" },
        .{ .operator = '^' },
        .{ .num = "3" },
        .eof,
    };
    for (tokens) |token| {
        const tok = lex.nextToke();
        try ex(token, tok);
    }
}
fn testRpm(input: []const u8, expected_output: []const u8) !void {
    try std.testing.expectEqualSlices(u8, expected_output, input);
}
