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
const ArgError = App.ArgError;
const Db = @import("./db/db.zig").DB;

const VERSION = "0.1.0";
const USAGE =
    \\CLI Calculator App
    \\------------------
    \\A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions for length and area.
;
const MAIN_OUT_FORMATE =
    \\The input is :: {s} ::
    \\Ans: {d}
;
const NO_HISTORY_MES =
    \\No history available yet.
    \\Start by running a calculation to save your work.
    \\Use -h or --help for more info.
;

fn getConfFile(alloc: std.mem.Allocator) !std.fs.File {
    if (std.zig.EnvVar.HOME.getPosix()) |home| {
        const dir_path = try std.fs.path.join(alloc, &.{ home, ".config/z_math" });
        defer alloc.free(dir_path);
        const file_path = try std.fs.path.join(alloc, &.{ dir_path, ".zmath" });
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

    // good idea to pass EXResCode to get extended result codes (more detailed error codes)
    var db = try Db.init(allocator);
    defer db.deinit();
    // db.addExpr("560 * 10", "5600", "789");
    // db.delExpr(16);
    // db.delRangeExpr(4, 5);
    const rows = try db.getExprs(.{ .limit = 0 });
    defer {
        for (rows) |row| row.destory(allocator);
        allocator.free(rows);
    }
    for (rows) |v| {
        std.debug.print("Id: {d} input: {s} output {s} expi_id {s} time {s} \n", .{ v.id, v.input, v.output, v.execution_id, v.created_at });
    }
    if (0 == 0) return;

    var cli = try Cli.init(allocator, "Z Math", USAGE, VERSION);
    defer cli.deinit();

    const con_file = try getConfFile(allocator);
    defer con_file.close();
    const con_stat = try con_file.stat();

    cli.parse() catch |e| {
        if (e == ZAppError.exit) return;
        if (e == ArgError.ArgValueNotGiven) {
            std.debug.print("{s}", .{cli.errorMess});
            return;
        }
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

            const outpust = try std.fmt.allocPrint(allocator, MAIN_OUT_FORMATE, .{ input, try eval.eval() });
            defer allocator.free(outpust);
            print("\x1b[32m{s}\x1b[0m", .{outpust});
            _ = try con_file.writeAll(outpust);
            _ = try con_file.writeAll("\r\n");
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
            const file_size = try con_file.getEndPos();
            if (file_size == 0) {
                std.debug.print(NO_HISTORY_MES, .{});
                return;
            }
            const buf = try allocator.alloc(u8, try con_file.getEndPos());
            defer allocator.free(buf);
            _ = try con_file.readAll(buf);
            const is_earlier = try cli.getBoolArg("-e");
            const limit = try cli.getNumArg("-l");
            if (is_earlier) {
                print_earlier_history(buf, limit);
            } else {
                print_recent_history(buf, limit);
            }
            return;
        },
    }
}

fn print_recent_history(buf: []const u8, limit: ?i32) void {
    var i: usize = buf.len - 3;
    var point: usize = buf.len - 1;
    var count: ?i32 = limit;
    while (i > 0) : (i -= 1) {
        if (i > 0) {
            if (count != null and count == 0) break;
            if (i == 1) {
                std.debug.print("\n{s}\n", .{buf[i - 1 .. point]});
            }
            if (buf[i] == '\n' and buf[i - 1] == '\r') {
                std.debug.print("{s}\n", .{buf[i..point]});
                point = i;
                if (count) |c| {
                    count = c - 1;
                }
            }
        }
    }
}
fn print_earlier_history(buf: []const u8, limit: ?i32) void {
    var i: usize = 0;
    var point: usize = 0;
    var count: ?i32 = limit;
    while (i < buf.len) : (i += 1) {
        if (buf.len > i) {
            if (count != null and count == 0) break;
            if (buf[i] == '\r' and buf[i + 1] == '\n') {
                std.debug.print("{s}\n", .{buf[point..i]});
                point = i;
                if (count) |c| {
                    count = c - 1;
                }
            }
        }
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
