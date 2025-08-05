const std = @import("std");
const builtin = @import("builtin");

const evalStruct = @import("eval.zig");
const ZAppError = @import("./errors.zig").ZAppErrors;
const assert = @import("./assert/assert.zig").assert;
const parser = @import("./parser.zig");
const lexer = @import("./lexer.zig");
const Order = @import("./db/sql_query.zig").Order;
const Token = @import("./token.zig").Token;
const zarg = @import("zarg");
const CliCmds = @import("cli_commands.zig");
const Db = @import("./db/db.zig").DB;
const utils = @import("./utils.zig");
const Version = @import("version.zig");

const Parser = parser.Parser;
const print = std.debug.print;
const Lexer = lexer.Lexer;
const Eval = evalStruct.Eval;
const ZColor = zarg.ZColor;

const Length = @import("./unit/length.zig");
const Volume = @import("./unit/volume.zig");
const Tempe = @import("./unit/temp.zig");

const NumWord = @import("num_words.zig");
const fmtCurr = @import("rupees_formate.zig");
const Exchange = @import("pkg/exchange_rate.zig");
const build_options = @import("build_options");

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

fn genVersion(version_form: zarg.VersionCallFrom) []const u8 {
    return switch (version_form) {
        .version => Version.comptimeStr(),
        .help => build_options.version_string,
    };
}

var header_style: ZColor.Style = .{
    .fgColor = ZColor.BrightCyan,
};

var answer_style: ZColor.Style = .{
    .fontStyle = .{
        .doublyUnderline = true,
        .italic = true,
    },
    .fgColor = .toColor(192),
};
var answer_word_style: ZColor.Style = .{
    .fontStyle = .{ .bold = true },
    .fgColor = .toColor(105),
};

var answer_currency_style: ZColor.Style = .{
    .fontStyle = .{ .bold = true },
    .fgColor = .toColor(84),
};

pub fn main() !void {
    const exe_id = std.crypto.random.intRangeAtMost(u64, 1000, 15000);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var db = try Db.init(allocator);
    defer db.deinit();

    var cli = try zarg.Cli(CliCmds.MyCLiCmds).init(
        allocator,
        "Z Math",
        USAGE,
        .{ .fun = &genVersion },
        &CliCmds.myCLiCmdList,
    );

    defer cli.deinit();
    cli.parse() catch |err| {
        try cli.printParseError(err);
        return;
    };

    const input = try cli.getAllPosArgAsStr() orelse "";
    defer allocator.free(input);
    var lex = Lexer.init(input, allocator);

    switch (cli.running_cmd.name) {
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
            const output_num: f128 = try eval.eval();
            // FIX: The number printed is not correct above sqr(114)
            const output = try std.fmt.allocPrint(allocator, "{d}", .{output_num});
            defer allocator.free(output);

            if (builtin.os.tag == .windows) _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

            var writer = std.io.getStdOut().writer();

            db.addExpr(input, output, "root", exe_id);
            if (try cli.getBoolArg("--raw")) {
                try writer.print("{s}", .{output});
                return;
            }

            try header_style.fmtRender("The input is :: {s} ::\n", .{input}, writer);
            try answer_style.fmtRender("Ans: {s}\n", .{output}, writer);
            if (try cli.getStrArg("--currency")) |cr| {
                const curr = std.meta.stringToEnum(Exchange.Currency, cr) orelse {
                    std.debug.print("Invalid Currency: {s}. Use --currency 'list' to get the list of available currency\n", .{cr});
                    return;
                };
                switch (curr) {
                    .list => try Exchange.Currency.printAvailable(writer),
                    else => {
                        const exchange_curr = try Exchange.rate(allocator, output_num, curr);
                        const nums = try fmtCurr.formateToRupees(allocator, exchange_curr);
                        defer allocator.free(nums);
                        print("Exchange rate for {d} {s} is {s}\n", .{ output_num, @tagName(curr), nums });
                    },
                }
            }
            if (try cli.getBoolArg("-i")) {
                const nums = try fmtCurr.formateToRupees(allocator, output_num);
                defer allocator.free(nums);
                try answer_currency_style.fmtRender("{s}\n", .{nums}, writer);
            }
            if (try cli.getBoolArg("--word")) {
                const word = try NumWord.floatToWord(allocator, output_num);
                defer allocator.free(word);
                try answer_word_style.fmtRender("{s}\n", .{word}, writer);
            }
            try writer.print("\n", .{});
        },
        .delete => {
            if (try cli.getStrArg("--range")) |range| {
                var ranges = std.mem.splitSequence(u8, range, "..");
                const from: u64 = try utils.parseUintBase10(u64, ranges.next());
                const to: u64 = try utils.parseUintBase10(u64, ranges.next());
                if (from == 0 or to == 0) {
                    std.debug.print("[Error] From Or to cant be 0. This could happen if letter or symbols are provided.", .{});
                    std.process.exit(1);
                }

                db.delRangeExpr(from, to);
                std.debug.print("Deleted entries {d}..{d} ", .{ from, to });
            }
            if (try cli.getBoolArg("--all")) {
                db.delAllExpr();
                std.debug.print("All entries have been successfully deleted.\n", .{});
            }
        },
        .length => {
            if (try cli.getBoolArg("-u")) {
                Length.printUnits();
                return;
            }
            var lenght = Length.init(input, &lex);
            const out = try lenght.calculateLenght();
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, lenght.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, "length", exe_id);
        },
        .volume => {
            if (try cli.getBoolArg("-u")) {
                Volume.printUnits();
                return;
            }
            var volume = Volume.init(input, &lex);
            const out = try volume.calculate();
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, volume.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, @tagName(cli.running_cmd.name), exe_id);
        },
        .temp => {
            if (try cli.getBoolArg("-u")) {
                Tempe.printUnits();
                return;
            }
            var tempe = Tempe.init(input, &lex);
            const out = try tempe.calculate();
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, @tagName(tempe.to.?.name) });
            defer allocator.free(output);
            db.addExpr(input, output, @tagName(cli.running_cmd.name), exe_id);
        },
        .area => {
            std.debug.panic("\x1b[1;91mArea not Implemented\x1b[0m", .{});
        },
        .history => {
            const is_id = try cli.getBoolArg("-id");
            const order = if (try cli.getBoolArg("-e")) Order.ASC else Order.DESC;
            if (try cli.getBoolArg("--all")) {
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
            const limit: u64 = if (try cli.getNumArg("-l")) |l| @intCast(l) else 5;
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
        .config => {
            const showDb = try cli.getBoolArg("-dp");
            if (showDb) {
                std.debug.print("{s}\n", .{db.path});
                return;
            }
        },
        .completion => {
            const opts = try CliCmds.MyCLiCmds.getCmdNameList(allocator);
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
