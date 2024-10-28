const std = @import("std");

const evalStruct = @import("eval.zig");
const ZAppError = @import("./errors.zig").ZAppErrors;
const assert = @import("./assert/assert.zig").assert;
const parser = @import("./parser.zig");
const Length = @import("./unit/length.zig");
const lexer = @import("./lexer.zig");
const Order = @import("./db/sql_query.zig").Order;
const Token = @import("./token.zig").Token;
const cmds = @import("./zarg/cmd.zig");
const Db = @import("./db/db.zig").DB;

const Parser = parser.Parser;
const print = std.debug.print;
const Lexer = lexer.Lexer;
const Eval = evalStruct.Eval;
const Cmd = cmds.Cli;

const VERSION = "0.2.9";
const USAGE =
    \\CLI Calculator App
    \\------------------
    \\A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions for length and area.
;
const NO_HISTORY_MES =
    \\No history available yet.
    \\Start by running a calculation to save your work.
    \\Use -h or --help for more info.
;

const AUTOCOMPLETION =
    \\ _m_cli_autocomplete() {{
    \\     local cur prev opts
    \\     COMPREPLY=()
    \\
    \\     # Get the current word the user is typing
    \\     cur="${{COMP_WORDS[COMP_CWORD]}}"
    \\
    \\     # Get the previous word on the command line
    \\     prev="${{COMP_WORDS[COMP_CWORD-1]}}"
    \\
    \\     # Define possible commands for autocompletion
    \\     opts="{s}"
    \\
    \\     # Use compgen to generate the possible completions based on cur
    \\     COMPREPLY=( $(compgen -W "${{opts}}" -- ${{cur}}) )
    \\
    \\     return 0
    \\ }}
    \\
    \\ complete -F _m_cli_autocomplete m
;

pub fn main() !void {
    const exe_id = std.crypto.random.intRangeAtMost(u64, 1000, 15000);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var db = try Db.init(allocator);
    defer db.deinit();

    var cmd = try Cmd.init(allocator, "Z Math", USAGE, VERSION);
    defer cmd.deinit();
    try cmd.parse();

    const input = cmd.data;
    var lex = Lexer.init(input, allocator);

    switch (cmd.cmd.name) {
        .root => {
            // FIX: error out on words,
            var par = try Parser.init(input, &lex, allocator);
            defer par.deinit();
            try par.parse();

            par.evaluate_errors(input) catch |e| {
                if (e == ZAppError.exit) return;
                return e;
            };

            var eval = Eval.init(&par.ast, allocator);
            defer eval.deinit();
            const output = try std.fmt.allocPrint(allocator, "{d}", .{try eval.eval()});
            defer allocator.free(output);

            db.addExpr(input, output, exe_id);
            std.debug.print(" \x1b[0;36mThe input is :: {s} ::\x1b[0m\n", .{input});
            std.debug.print(" \x1b[3;21;32mAns: {s}\x1b[0m\n", .{output});
            std.debug.print("\n", .{});
        },
        .delete => {
            if (try cmd.getStrArg("--range")) |range| {
                var ranges = std.mem.splitSequence(u8, range, "..");
                const from: u64 = if (ranges.next()) |n| std.fmt.parseUnsigned(u64, n, 10) catch |e| switch (e) {
                    error.InvalidCharacter => 0,
                    else => return e,
                } else 0;
                const to: u64 = if (ranges.next()) |n| std.fmt.parseUnsigned(u64, n, 10) catch |e| switch (e) {
                    error.InvalidCharacter => 0,
                    else => return e,
                } else 0;
                if (from == 0 or to == 0) {
                    std.debug.print("[Error] From Or to cant be 0. This could happen if letter or symbols are provided.", .{});
                    std.process.exit(1);
                }

                db.delRangeExpr(from, to);
                std.debug.print("Deleted entries {d}..{d} ", .{ from, to });
            }
            if (try cmd.getBoolArg("--all")) {
                db.delAllExpr();
                std.debug.print("All entries have been successfully deleted.\n", .{});
            }
        },
        .length => {
            if (try cmd.getBoolArg("-u")) {
                Length.printUnits();
                return;
            }
            var lenght = Length.init(input, &lex);
            const out = try lenght.calculateLenght();
            _ = out;
        },
        .area => {
            std.debug.panic("\x1b[1;91mArea not Implemented\x1b[0m", .{});
        },
        .history => {
            const is_id = try cmd.getBoolArg("-id");
            const order = if (try cmd.getBoolArg("-e")) Order.ASC else Order.DESC;
            if (try cmd.getBoolArg("--all")) {
                const rows = try db.getAllExprs(order);
                defer {
                    for (rows) |row| row.destory(allocator);
                    allocator.free(rows);
                }
                if (rows.len == 0) {
                    std.debug.print(NO_HISTORY_MES, .{});
                    return;
                }
                for (rows) |v| {
                    v.printStrExper(is_id);
                }
                return;
            }
            const limit: u64 = if (try cmd.getNumArg("-l")) |l| @intCast(l) else 5;
            const rows = try db.getExprs(.{ .limit = limit, .order = order });
            defer {
                for (rows) |row| row.destory(allocator);
                allocator.free(rows);
            }
            if (rows.len == 0) {
                std.debug.print(NO_HISTORY_MES, .{});
                return;
            }
            for (rows) |v| {
                v.printStrExper(is_id);
            }

            return;
        },
        .completion => {
            const opts = try cmds.CmdName.getCmdNameList(allocator);
            defer allocator.free(opts);
            std.debug.print(AUTOCOMPLETION, .{std.mem.trimRight(u8, opts, " ")});
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
