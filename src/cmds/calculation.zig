const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const zarg = @import("zarg");
const Style = zarg.Style;
const Color = Style.Color;
const ComputedArg = zarg.Cli.ComputedArgs;

const CliCmds = @import("../cli_commands.zig");
const Db = @import("../db/db.zig").DB;
const Eval = @import("../eval.zig").Eval;
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const pkg = @import("../pkg/pkg.zig");
const NumWord = pkg.NumWord;
const FmtCurr = pkg.FmtCurr;
const Exchange = pkg.Exchange;

const std = @import("std");

const Self = @This();
alloc: Allocator,
input: []const u8,
computed_number: f128 = undefined,
is_computed_number_set: bool = false,

var header_style: Style = .{
    .fgColor = Style.BrightCyan,
};

var answer_style: Style = .{
    .fontStyle = .{
        .doublyUnderline = true,
        .italic = true,
    },
    .fgColor = .toColor(192),
};

var answer_word_style: Style = .{
    .fontStyle = .{ .bold = true },
    .fgColor = .toColor(105),
};

var answer_currency_style: Style = .{
    .fontStyle = .{ .bold = true },
    .fgColor = .toColor(84),
};

pub fn init(alloc: Allocator, input: []const u8) Self {
    return .{
        .alloc = alloc,
        .input = input,
    };
}

pub fn compute(self: *Self, lex: *Lexer) !f128 {

    // FIX: error out on words,
    var par = try Parser.init(self.input, lex, self.alloc);
    defer par.deinit();
    try par.parse();

    try par.evaluate_errors(self.input);

    var eval = Eval.init(&par.ast, self.alloc);
    defer eval.deinit();

    const computed_number = try eval.eval();
    self.computed_number = computed_number;
    self.is_computed_number_set = true;
    return computed_number;
}

/// Displays computation results with various formatting options including currency conversion,
/// word representation, and database logging.
///
/// # Returns
/// Returns `void` on success, or an error if:
/// - Computation hasn't been completed (`error.ComputationNotDone`)
///     * run [compute(...)] this function before calling this function.
/// ```
pub fn dump(self: *const Self, cli: *ComputedArg, db: *Db, exe_id: u64, writer: *std.io.Writer) !void {
    if (!self.is_computed_number_set) return error.ComputationNotDone;

    // FIX: The number printed is not correct above sqr(114)
    const output = try std.fmt.allocPrint(self.alloc, "{d}", .{self.computed_number});
    defer self.alloc.free(output);

    if (builtin.os.tag == .windows) _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    db.addExpr(self.input, output, "root", exe_id);
    if (try cli.getBoolArg("--raw")) {
        try writer.print("{s}", .{output});
        return;
    }

    try header_style.fmtRender("The input is :: {s} ::\n", .{self.input}, writer);
    try answer_style.fmtRender("Ans: {s}\n", .{output}, writer);
    if (try cli.getBoolArg("-i")) {
        const nums = try FmtCurr.formateToRupees(self.alloc, self.computed_number);
        defer self.alloc.free(nums);
        try answer_currency_style.fmtRender("{s}\n", .{nums}, writer);
    }
    const is_word_fmt = try cli.getBoolArg("--word");
    if (is_word_fmt) {
        const word = try NumWord.floatToWord(self.alloc, self.computed_number);
        defer self.alloc.free(word);
        try answer_word_style.fmtRender("{s}\n", .{word}, writer);
    }
    if (try cli.getStrArg("--currency")) |cr| {
        const curr = std.meta.stringToEnum(Exchange.Currency, cr) orelse {
            std.debug.print("Invalid Currency: {s}. Use --currency 'list' to get the list of available currency\n", .{cr});
            return;
        };
        switch (curr) {
            .list => try Exchange.Currency.printAvailable(writer),
            else => {
                const exchange_curr = try Exchange.rate(self.alloc, self.computed_number, curr, .inr);
                const nums = try FmtCurr.formateToRupees(self.alloc, exchange_curr);
                defer self.alloc.free(nums);
                try writer.print("Exchange rate for {d} {s} is {s}\n", .{ self.computed_number, @tagName(curr), nums });
                if (is_word_fmt) {
                    const word = try NumWord.floatToWord(self.alloc, exchange_curr);
                    defer self.alloc.free(word);
                    try answer_word_style.fmtRender("{s}\n", .{word}, writer);
                }
            },
        }
    }
    try writer.print("\n", .{});
}
