const std = @import("std");
const Allocator = std.mem.Allocator;

// Welcome to the interactive mode! Type your expressions one by one. Each expression will be evaluated based on the previous result.
//
// Type `exit` or `quit` to leave the interactive mode.
// CLI Calculator App
// ------------------
// A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions for length and area.
//
// Usage:
//   calc [OPTIONS] "EXPRESSION"
//   calc [OPTIONS] convert VALUE FROM_UNIT to TO_UNIT
//
// Options:
//   -i, --interactive    Start calculator in interactive mode. Keep evaluating expressions based on previous results.
//   -h, --help           Show this help message and exit.

pub const CmdName = enum { root, lenght, area, history };

pub const Arg = struct {
    long: ?[]const u8 = null,
    short: ?u8 = null,
    info: []const u8,
    type: enum { string, bool },
};

pub const Cmd = struct {
    name: CmdName,
    usage: []const u8,
    info: ?[]const u8 = null,
    options: ?[]const Arg = null,
    argData: ?[]Arg = null,
};

const cmdList: []const Cmd = &.{
    .{
        .name = .root,
        .usage = "m [OPTIONS] \"EXPRESSION\"",
        .options = &.{
            .{
                .long = "interactive",
                .short = 'i',
                .info = "Start interactive mode to evaluate expressions based on previous results.",
                .type = .bool,
            },
            .{
                .long = "all",
                .short = 'a',
                .info = "Start interactive mode to evaluate expressions based on previous results.",
                .type = .bool,
            },
        },
    },
    .{
        .name = .lenght,
        .usage = "m lenght [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .info = "This command convert values between different units of length.",
        .options = null,
    },
    .{
        .name = .area,
        .usage = "m area [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .info = "This command convert values between different units of area.",
        .options = null,
    },
    .{
        .name = .history,
        .usage = "m history [OPTIONS] ",
        .info = "This command displays the history of previously evaluated expressions.",
        .options = null,
    },
};

pub const Cli = struct {
    const Self = @This();

    args: std.process.ArgIterator,
    alloc: Allocator,

    name: []const u8,
    description: ?[]const u8 = null,

    cmdsOptions: []const Cmd,
    cmd: ?Cmd = null,

    pub fn init(allocate: Allocator, name: []const u8, description: ?[]const u8) Self {
        const args = try std.process.argsWithAllocator(allocate);
        return .{
            .alloc = allocate,
            .args = args,
            .name = name,
            .description = description,
            .cmdsOptions = cmdList,
        };
    }
    pub fn parse(self: *Self) !void {
        errdefer self.args.deinit();
    }
    pub fn help(self: Self) void {
        const padding = 20;
        if (self.description) |dis| {
            std.debug.print("{s}\n\n", .{dis});
        }
        const cmd_opt = self.cmdsOptions[0];
        std.debug.print("USAGE: \n", .{});
        std.debug.print("  {s}\n\n", .{cmd_opt.usage});
        std.debug.print("OPTIONS: \n", .{});
        if (cmd_opt.options) |opt| {
            for (opt) |value| {
                var opt_len: usize = 0;
                if (value.short) |s| {
                    opt_len += 4;
                    std.debug.print(" -{c},", .{s});
                }
                if (value.long) |l| {
                    opt_len += (l.len + 2);
                    std.debug.print(" --{s}", .{l});
                }
                for (0..(padding - opt_len)) |_| {
                    std.debug.print(" ", .{});
                }
                std.debug.print("{s}\n", .{value.info});
            }
        }
        std.debug.print(" -h, --help          Help message.\n", .{});
        std.debug.print("\n", .{});
        if (cmd_opt.name != .root) return;
        std.debug.print("COMMANDS: \n", .{});
        for (self.cmdsOptions) |value| {
            if (value.info) |info| {
                const name = @tagName(value.name);
                std.debug.print(" {s}", .{name});
                for (0..(padding - name.len)) |_| {
                    std.debug.print(" ", .{});
                }
                std.debug.print("{s}\n", .{info});
            }
        }
    }
    // pub fn parse(self: *Self) void {}
    pub fn deinit(self: *Self) void {
        self.args.deinit();
    }
};
const usage =
    \\CLI Calculator App
    \\------------------
    \\A simple and powerful command-line calculator for evaluating math expressions and performing unit conversions for length and area.
;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var cli = Cli.init(allocator, "Z Math", usage);
    defer cli.deinit();
    cli.help();
    // std.debug.print("{any}", .{cli.cmdsOptions});
}
