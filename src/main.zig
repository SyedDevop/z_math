const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const evalStruct = @import("eval.zig");

const print = std.debug.print;
const Lexer = lexer.Lexer;
const Token = lexer.Token;
const Parser = parser.Parser;
const Eval = evalStruct.Eval;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lex = Lexer.init("3 + 4 * 680+ 98* 5665 - 454165 * 8787 ");
    var par = try Parser.init(&lex, allocator);
    defer par.deinit();
    try par.parse();

    var result = std.AutoHashMap(usize, f64).init(allocator);
    defer result.deinit();

    var eval = Eval.init(&par.ast, allocator);
    defer eval.deinit();

    print("Ans: {d}\n", .{try eval.eval()});
}

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
