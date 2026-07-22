const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const print = std.debug.print;

const ZAppError = @import("./errors.zig").ZAppErrors;
const assert = @import("./assert/assert.zig").assert;
const Order = @import("./db/sql_query.zig").Order;
const Token = @import("./token.zig").Token;
const Db = @import("./db/db.zig").DB;
const utils = @import("./utils.zig");
const Version = @import("version.zig");

const evalStruct = @import("eval.zig");
const Eval = evalStruct.Eval;

const parser = @import("./parser.zig");
const Parser = parser.Parser;

const Lexer = @import("./lexer.zig");

const CliCmds = @import("cli_commands.zig");
const zarg = @import("zarg");
const Cli = zarg.Cli;
const Style = zarg.Style;
const Color = zarg.Style.Color;

const Unit = @import("unit/unit_object.zig");
const _unit = @import("unit/unit.zig");
const Length = _unit.Length;
const Volume = _unit.Volume;
const Tempe = _unit.Tempe;
const Mass = _unit.Mass;

const pkg = @import("pkg/pkg.zig");
const NumWord = pkg.NumWord;
const FmtCurr = pkg.FmtCurr;
const Exchange = pkg.Exchange;

const USAGE =
    \\CLI Calculator App
    \\------------------
    \\A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions.
;
const NO_HISTORY_MES =
    \\No history available yet.
    \\Start by running a calculation to save your work.
    \\Use -h or --help for more info.
;

const cmds = @import("./cmds/cmds.zig");
const Calculation = cmds.Calculation;

var answer_word_style: Style = .{
    .fontStyle = .{ .bold = true },
    .fgColor = .toColor(105),
};

fn genVersion(version_form: Cli.VersionCallFrom) []const u8 {
    return switch (version_form) {
        .version => Version.comptimeStr(),
        .help => build_options.version_string,
    };
}
pub fn main(init: std.process.Init) !void {
    // if (true) return;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_io = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    var stdout = &stdout_io.interface;

    const rnd_io = std.Random.IoSource{ .io = init.io };
    const rnd = rnd_io.interface();
    const exe_id = rnd.intRangeAtMost(u64, 1000, 15000);

    const allocator = init.gpa;

    var db = try Db.init(allocator, init.environ_map);
    defer db.deinit();

    var cli = try Cli.CliInit(CliCmds.MyCLiCmds).init(
        allocator,
        "Z Math",
        USAGE,
        .{ .fun = &genVersion },
        &CliCmds.myCLiCmdList,
    );
    defer cli.deinit();

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    cli.parse(args) catch |err| {
        try cli.printParseError(err, stdout);
        try stdout.flush();
        return;
    };

    const input = try cli.getAllPosArgAsStr() orelse "";
    defer allocator.free(input);
    var lex = Lexer.init(input, allocator);
    defer stdout.flush() catch unreachable;
    switch (cli.running_cmd.name) {
        .root => {
            var calculation = Calculation.init(allocator, input);
            _ = calculation.compute(&lex) catch |err| {
                if (err == ZAppError.exit) return;
                return err;
            };
            try calculation.dump(init.io, &cli.computed_args, &db, exe_id, stdout);
        },

        .exchange => {
            if (try cli.getBoolArg("list")) {
                try Exchange.Currency.printAvailable(stdout);
                return;
            }
            var from_curr: ?Exchange.Currency = null;
            var to_curr: ?Exchange.Currency = null;
            var num: f128 = 0;
            while (lex.hasTokes()) {
                const tok = try lex.nextToke();
                switch (tok) {
                    .word => |w| {
                        const curr = std.meta.stringToEnum(Exchange.Currency, w) orelse {
                            const prefix = Style.Color.renderComptime("✘ Invalid currency:", .toAnsi8(197), null);
                            const info = Style.Color.renderComptime("   ⚠ Hint:", .toAnsi8(226), null);
                            std.debug.print("{s} '{s}' is not recognized.\n{s} Try --list or --help to see supported currencies.\n", .{ prefix, w, info });
                            return;
                        };
                        if (from_curr == null) {
                            from_curr = curr;
                        } else if (to_curr == null) {
                            to_curr = curr;
                        } else break;
                    },
                    .num => |n| num = n,
                    else => {},
                }
            }
            if (from_curr == null) from_curr = .usd;
            switch (from_curr.?) {
                .list => try Exchange.Currency.printAvailable(stdout),
                else => {
                    const exchange_curr = try Exchange.rate(allocator, init.io, num, from_curr.?, to_curr orelse .inr);
                    print("Exchange rate: {d} {t} = ", .{ num, from_curr.? });
                    if (to_curr == null or to_curr == .inr) {
                        const nums = try FmtCurr.formateToRupees(allocator, exchange_curr);
                        defer allocator.free(nums);
                        print("{s}\n", .{nums});
                    } else {
                        print("{d:0>6.3} {t}\n", .{ exchange_curr, to_curr.? });
                    }
                    if (try cli.getBoolArg("word")) {
                        const word = try NumWord.numToWord(allocator, @intFromFloat(exchange_curr));
                        defer allocator.free(word);
                        try answer_word_style.fmtRender("{s}\n", .{word}, stdout);
                    }
                },
            }
        },

        .delete => {
            if (try cli.getStrArg("range")) |range| {
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
            if (try cli.getBoolArg("all")) {
                db.delAllExpr();
                std.debug.print("All entries have been successfully deleted.\n", .{});
            }
        },

        .length => {
            var length = Unit.init(input, &lex, &Length.LENGTH_MAP);
            if (try cli.getBoolArg("l")) {
                try length.printUnits(stdout, "Length");
                return;
            }
            const out = try length.calculate(stdout);
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, length.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, "length", exe_id);
        },

        .mass => {
            var mass = Unit.init(input, &lex, &Mass.massMap);

            if (try cli.getBoolArg("l")) {
                try mass.printUnits(stdout, "Mass");
                return;
            }
            const out = try mass.calculate(stdout);
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, mass.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, "mass", exe_id);
        },

        .volume => {
            var volume = Unit.init(input, &lex, &Volume.volMap);
            if (try cli.getBoolArg("l")) {
                try volume.printUnits(stdout, "Volume");
                return;
            }
            const out = try volume.calculate(stdout);
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, volume.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, @tagName(cli.running_cmd.name), exe_id);
        },

        .temp => {
            var tempe = Tempe.init(input, &lex);

            if (try cli.getBoolArg("l")) {
                try tempe.printUnits(stdout);
                return;
            }
            const out = try tempe.calculate(stdout);
            const output = try std.fmt.allocPrint(allocator, "{d} {s}", .{ out, tempe.unit.to.?.name });
            defer allocator.free(output);
            db.addExpr(input, output, @tagName(cli.running_cmd.name), exe_id);
        },

        .area => {
            std.debug.panic("\x1b[1;91mArea not Implemented\x1b[0m", .{});
        },

        .history => {
            const is_id = try cli.getBoolArg("id");
            const order = if (try cli.getBoolArg("e")) Order.ASC else Order.DESC;
            if (try cli.getBoolArg("all")) {
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
            const limit: u64 = if (try cli.getNumArg("l")) |l| @intCast(l) else 5;
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
            const showDb = try cli.getBoolArg("dp");
            if (showDb) {
                std.debug.print("{s}\n", .{db.path});
                return;
            }
        },

        .completion => {
            const bash = try cli.getCompletion(allocator, .bash);
            defer allocator.free(bash);
            try stdout.print("{s}\n", .{bash});
        },
    }
}
test {
    _ = @import("token.zig");
    _ = @import("lexer.zig");
    _ = @import("pkg/rupees_formate_test.zig");
    _ = @import("pkg/num_words_test.zig");
}
