const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");

//Input           :: 3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3
//Expected        :: 3 4 2 * 1 5 - 2 3 ^ ^ / +
//Current OutPuth :: 3 4 + 2 1 * 5 2 / 3 - ^ ^

//Input           :: 5 + ((1 + 2) * 4) - 3
//Expected        :: 5 1 2 + 4 * + 3 -
//Current OutPuth :: 5 1 + 2 4 + 3 * -

// const print = std.debug.print;
const Lexer = lexer.Lexer;
const Token = lexer.Token;
const Parser = parser.Parser;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer _ = gpa.deinit();

    var lex = Lexer.init("4 - 5 + 10");
    var par = try Parser.init(&lex);
    try par.parse();

    // std.debug.print("\n", .{});

    // try pretty.print(alloc, par.tree, .{
    //     .max_depth = 0,
    //     .struct_max_len = 0,
    // });
    // ast.print();

    // var outList = std.ArrayList(Token).init(allocator);
    // defer outList.deinit();
    // var opList = std.ArrayList(Token).init(allocator);
    // defer opList.deinit();
    //
    // while (lex.hasTokes()) {
    //     const tok = try lex.nextToke();
    //     // std.debug.print("{any}\n", .{tok});
    //     switch (tok) {
    //         .illegal => |il_tok| {
    //             std.debug.print("{s}", .{il_tok});
    //             break;
    //         },
    //         else => {
    //             try outList.append(tok);
    //         },
    //     }
    // }
    //
    // if (opList.items.len > 0) {
    //     try outList.appendSlice(opList.items);
    // }
    // std.debug.print("OutList is :: {s}\n", .{try Token.arryToString(outList.items)});
    // std.debug.print("OpList  is :: {s}\n", .{try Token.arryToString(opList.items)});
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
// test "Parse to RPM" {
//     try testRpm("3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3", "342*15-23^^/+");
// }

const ex = std.testing.expectEqualDeep;
// test "Lexer" {
//     var lex = Lexer.init("3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3");
//     const tokens = [_]Token{
//         .{ .num = "3" },
//         .{ .operator = '+' },
//         .{ .num = "4" },
//         .{ .operator = '*' },
//         .{ .num = "2" },
//         .{ .operator = '/' },
//         .lparen,
//         .{ .num = "1" },
//         .{ .operator = '-' },
//         .{ .num = "5" },
//         .rparen,
//         .{ .operator = '^' },
//         .{ .num = "2" },
//         .{ .operator = '^' },
//         .{ .num = "3" },
//         .eof,
//     };
//     for (tokens) |token| {
//         const tok = lex.nextToke();
//         try ex(token, tok);
//     }
// }
//
// fn testRpm(input: []const u8, expected_output: []const u8) !void {
//     try std.testing.expectEqualSlices(u8, expected_output, input);
// }
