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
    info: ?[]const u8 = null,
    type: enum { string, bool },
};

pub const Cmd = struct {
    name: CmdName,
    usage: ?[]const u8,
    options: ?[]const Arg,
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
        },
    },
    .{
        .name = .lenght,
        .usage = "m lenght [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .options = null,
    },
    .{
        .name = .area,
        .usage = "m area [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .options = null,
    },
    .{
        .name = .history,
        .usage = "m history [OPTIONS] ",
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
            // .cmdsOptions = &.{
            //     .{
            //         .name = .{ .root = "Home" },
            //         .usage = "Hello",
            //         .options = &.{"-i"},
            //     },
            // },
        };
    }
    pub fn parse(self: *Self) !void {
        errdefer self.args.deinit();
    }
    pub fn deinit(self: *Self) void {
        self.args.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var cli = Cli.init(allocator, "Z Math", "Hello");
    defer cli.deinit();

    std.debug.print("{any}", .{cli.cmdsOptions});
}
