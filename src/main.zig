const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const evalStruct = @import("eval.zig");

const Token = @import("./token.zig").Token;
const print = std.debug.print;
const Lexer = lexer.Lexer;
const Parser = parser.Parser;
const Eval = evalStruct.Eval;

fn stringArg(alloc: std.mem.Allocator) ![]u8 {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.skip();

    var argList = std.ArrayList(u8).init(alloc);
    defer argList.deinit();

    while (args.next()) |arg| {
        try argList.appendSlice(arg);
        try argList.append(' ');
    }
    return try argList.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const input = try stringArg(allocator);
    defer allocator.free(input);
    print("\x1b[32mThe input is :: {s} ::\n\x1b[0m", .{input});
    var lex = Lexer.init(input, allocator);
    var par = try Parser.init(&lex, allocator);
    defer par.deinit();
    try par.parse();

    if (par.ast.len < 3) {
        std.debug.print("\x1b[33mWaring: The expression provided is too short. Please provide a longer or more detailed expression\x1b[0m", .{});
        return;
    }

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
