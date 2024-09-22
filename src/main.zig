const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const evalStruct = @import("eval.zig");

const Token = @import("./token.zig").Token;
const print = std.debug.print;
const Lexer = lexer.Lexer;
const Parser = parser.Parser;
const Eval = evalStruct.Eval;

fn stringArg(alloc: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.skip();

    var argList = std.ArrayList(u8).init(alloc);
    defer argList.deinit();

    while (args.next()) |arg| {
        try argList.appendSlice(std.mem.trim(u8, arg, " "));
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

    if (input.len <= 1) {
        print("\x1b[32mThe input is :: {s} ::\n\x1b[0m", .{input});
        std.debug.print("\x1b[33mWaring: The expression provided is too short. Please provide a longer or more detailed expression\x1b[0m\n", .{});
        return;
    }

    var lex = Lexer.init(input, allocator);
    var par = try Parser.init(input, &lex, allocator);
    defer par.deinit();
    try par.parse();

    if (par.errors.items.len > 0) {
        for (par.errors.items) |err| {
            if (err.level == .err) {
                print("The input is :: {s} ::\n\x1b[0m", .{input});
                std.debug.print("\x1b[31mError: {s}\x1b[0m\n", .{err.message});
            } else {
                std.debug.print("\x1b[33mWaring: {s}\x1b[0m\n", .{err.message});
            }
            if (err.token) |tok| {
                std.debug.print("\x1b[33mToke:: {any}\x1b[0m\n", .{tok});
            }
            if (err.message_alloced) {
                allocator.free(err.message);
            }
        }
        return;
    }

    var eval = Eval.init(&par.ast, allocator);
    defer eval.deinit();

    print("\x1b[32mThe input is :: {s} ::\n\x1b[0m", .{input});
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
