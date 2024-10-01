const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const evalStruct = @import("eval.zig");

const Token = @import("./token.zig").Token;
const App = @import("./cli.zig");
const ZAppError = @import("./errors.zig").ZAppErrors;
const print = std.debug.print;
const Parser = parser.Parser;
const Eval = evalStruct.Eval;
const Lexer = lexer.Lexer;
const Cli = App.Cli;

const VERSION = "0.1.0";
const USAGE =
    \\CLI Calculator App
    \\------------------
    \\A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions for length and area.
;
const MAIN_OUT_FORMATE =
    \\The input is :: {s} ::
    \\Ans: {d}
    \\
    \\
;

fn getConfFile(alloc: std.mem.Allocator) !std.fs.File {
    if (std.zig.EnvVar.HOME.getPosix()) |home| {
        const dir_path = try std.fs.path.join(alloc, &.{ home, ".config/.z_math" });
        defer alloc.free(dir_path);
        const file_path = try std.fs.path.join(alloc, &.{ dir_path, ".zmath.txt" });
        defer alloc.free(file_path);

        const file = std.fs.cwd().openFile(file_path, .{ .mode = .read_write }) catch |err| switch (err) {
            error.FileNotFound => brk: {
                if (std.fs.accessAbsolute(dir_path, .{}) == error.FileNotFound) {
                    try std.fs.makeDirAbsolute(dir_path);
                }
                const file = try std.fs.cwd().createFile(file_path, .{
                    .read = true,
                    .truncate = false,
                });
                break :brk file;
            },
            else => return err,
        };

        // const stat = try file.stat();
        // try file.seekTo(stat.size);
        return file;
    } else {
        std.debug.print("config path not found", .{});
        std.debug.print("Z_Math only supports the POSIX-compliant system.", .{});
        return ZAppError.exit;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var cli = Cli.init(allocator, "Z Math", USAGE, VERSION);
    defer cli.deinit();

    const con_file = try getConfFile(allocator);
    defer con_file.close();
    const con_stat = try con_file.stat();

    cli.parse() catch |e| {
        if (e == ZAppError.exit) return;
        return e;
    };

    const input = cli.data;

    // if (input.len <= 1) {
    //     print("\x1b[32mThe input is :: {s} ::\n\x1b[0m", .{input});
    //     std.debug.print("\x1b[33mWaring: The expression provided is too short. Please provide a longer or more detailed expression\x1b[0m\n", .{});
    //     return;
    // }

    var lex = Lexer.init(input, allocator);

    switch (cli.cmd.name) {
        .root => {
            var par = try Parser.init(input, &lex, allocator);
            defer par.deinit();
            try par.parse();

            par.evaluate_errors(input) catch |e| {
                if (e == ZAppError.exit) return;
                return e;
            };

            var eval = Eval.init(&par.ast, allocator);
            defer eval.deinit();

            try con_file.seekTo(con_stat.size);

            // print("\x1b[32mThe input is :: {s} ::\n\x1b[0m", .{input});
            // print("Ans: {d}\n", .{try eval.eval()});
            const outpust = try std.fmt.allocPrint(allocator, MAIN_OUT_FORMATE, .{ input, try eval.eval() });
            defer allocator.free(outpust);
            print("\x1b[32m{s}\x1b[0m", .{outpust});
            _ = try con_file.writeAll(outpust);
        },
        .lenght => {
            var c: u8 = 1;
            var from: f16 = 0;
            var to: f16 = 0;
            var val: f64 = 0;
            while (lex.hasTokes()) {
                const tok = try lex.nextToke();

                if (c == 1) {
                    from = Token.get_unit(tok) * -1;
                } else if (c == 3) {
                    val = 100;
                } else if (c == 5) {
                    to = Token.get_unit(tok) * -1;
                }
                c += 1;
            }
            std.debug.print("val{d} from{d}, to{d} = {d}", .{ val, from, to, std.math.pow(f64, val, from) * to });
        },
        .area => {
            std.debug.panic("\x1b[1;91mArea not Implemented\x1b[0m", .{});
        },
        .history => {
            const buf = try allocator.alloc(u8, try con_file.getEndPos());
            defer allocator.free(buf);
            // try con_file.seekFromEnd(0);
            _ = try con_file.readAll(buf);
            var it = std.mem.splitBackwardsSequence(u8, buf, "\n");
            _ = it.next();
            _ = it.next();
            while (it.next()) |a| {
                std.debug.print("{s}\n", .{a});
            }
            return;
            // std.debug.panic("\x1b[1;91History not Implemented\x1b[0m", .{});
        },
    }
}

const ex = std.testing.expectEqualDeep;
test "Lexer" {
    var lex = Lexer.init("3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3", std.testing.allocator);
    const tokens = [_]Token{
        .{ .num = 3 },
        .{ .operator = '+' },
        .{ .num = 4 },
        .{ .operator = '*' },
        .{ .num = 2 },
        .{ .operator = '/' },
        .lparen,
        .{ .num = 1 },
        .{ .operator = '-' },
        .{ .num = 5 },
        .rparen,
        .{ .operator = '^' },
        .{ .num = 2 },
        .{ .operator = '^' },
        .{ .num = 3 },
        .eof,
    };
    for (tokens) |token| {
        const tok = lex.nextToke();
        try ex(token, tok);
    }
}
test "Lexer Lenght" {
    var lex = Lexer.init("mm:45:ft", std.testing.allocator);
    const tokens = [_]Token{
        .mm,
        .colon,
        .{ .num = 45 },
        .colon,
        .ft,
        .eof,
    };
    for (tokens) |token| {
        const tok = lex.nextToke();
        try ex(token, tok);
    }
}
test "Read file" {
    if (std.zig.EnvVar.HOME.getPosix()) |home| {
        const dir_path = try std.fs.path.join(std.testing.allocator, &.{ home, ".config/.z_math" });
        defer std.testing.allocator.free(dir_path);
        // try std.fs.makeDirAbsolute(dir_path);

        const file_path = try std.fs.path.join(std.testing.allocator, &.{ dir_path, ".zmath.json" });
        defer std.testing.allocator.free(file_path);

        const file = std.fs.cwd().openFile(file_path, .{ .mode = .read_write }) catch |e| {
            switch (e) {
                .FileNotFound => {
                    try std.fs.cwd().createFile(file_path, .{});
                    return;
                },
                else => return e,
            }
        };

        defer file.close();
        const stat = try file.stat();
        try file.seekTo(stat.size);

        const bytes_written = try file.writeAll("\n--Uzer\nSyed Uzair||Hello||Jo||50||6011212");
        _ = bytes_written;

        try file.seekTo(0);
        var buffer: [100]u8 = undefined;
        _ = try file.readAll(&buffer);
        std.debug.print("{s}", .{buffer});
    } else {
        std.debug.print("conf_path Not found", .{});
    }
    // try std.testing.expect(std.mem.eql(u8, buffer[0..11], "Hello File!"));
}
