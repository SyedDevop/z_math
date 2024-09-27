const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CmdName = enum { root, lenght, area, history };
pub const ArgValue = union(enum) {
    str: ?[]const u8,
    bool: ?bool,
};
pub const Arg = struct {
    long: []const u8,
    short: []const u8,
    info: []const u8,
    value: ArgValue,
};

pub const ArgsList = std.ArrayList(Arg);

pub fn isHelpOption(opt: []const u8) bool {
    return (std.mem.eql(u8, "-h", opt) or std.mem.eql(u8, "--help", opt));
}
pub fn isVersionOption(opt: []const u8) bool {
    return (std.mem.eql(u8, "-v", opt) or std.mem.eql(u8, "--version", opt));
}
pub const Cmd = struct {
    name: CmdName,
    usage: []const u8,
    info: ?[]const u8 = null,
    options: ?[]const Arg = null,
};
const rootCmd = Cmd{
    .name = .root,
    .usage = "m [OPTIONS] \"EXPRESSION\"",
    .options = &.{
        .{
            .long = "--interactive",
            .short = "-i",
            .info = "Start interactive mode to evaluate expressions based on previous results.",
            .value = .{ .bool = null },
        },
    },
};
const cmdList: []const Cmd = &.{
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

pub const CliErrors = error{
    exit,
};

pub const Cli = struct {
    const Self = @This();
    alloc: Allocator,

    name: []const u8,
    description: ?[]const u8 = null,

    computed_args: ArgsList,
    subCmds: []const Cmd,
    rootCmd: Cmd,
    cmd: Cmd,
    data: []const u8,

    version: []const u8,

    pub fn init(allocate: Allocator, name: []const u8, description: ?[]const u8, version: []const u8) Self {
        return .{
            .alloc = allocate,
            .name = name,
            .description = description,
            .subCmds = cmdList,
            .rootCmd = rootCmd,
            .cmd = rootCmd,
            .version = version,
            .computed_args = ArgsList.init(allocate),
            .data = "",
        };
    }
    pub fn parse(self: *Self) !void {
        const args = try std.process.argsAlloc(self.alloc);
        defer std.process.argsFree(self.alloc, args);

        if (args.len < 2) {
            try self.help();
            return CliErrors.exit;
        }
        var idx: usize = 1;
        const cmdEnum = std.meta.stringToEnum(CmdName, args[idx]);
        const cmd = self.getCmd(cmdEnum);
        self.cmd = cmd;

        if (cmd.name != .root) {
            idx += 1;
            if (args.len < 3) {
                try self.help();
                return CliErrors.exit;
            }
        }
        if (isHelpOption(args[idx])) {
            try self.help();
            return CliErrors.exit;
        } else if (isVersionOption(args[idx])) {
            std.debug.print("Z Math {s}", .{self.version});
            return CliErrors.exit;
        }
        if (self.cmd.options) |opt| {
            for (opt) |arg| {
                if (std.mem.eql(u8, arg.long, args[idx]) or std.mem.eql(u8, arg.short, args[idx])) {
                    idx += 1;
                    switch (arg.value) {
                        .bool => {
                            var copy_arg = arg;
                            copy_arg.value = .{ .bool = true };
                            try self.computed_args.append(copy_arg);
                        },
                        .str => {
                            var copy_arg = arg;
                            copy_arg.value = .{ .str = "Hello  Uzair" };
                            try self.computed_args.append(copy_arg);
                            // TODO: Parse the key:value for string option.
                            std.debug.panic("String option not implemented.", .{});
                        },
                    }
                } else {
                    switch (arg.value) {
                        .bool => |b| if (b != null) try self.computed_args.append(arg),
                        .str => |s| if (s != null) try self.computed_args.append(arg),
                    }
                }
            }
        }

        var argList = std.ArrayList(u8).init(self.alloc);
        defer argList.deinit();
        for (args[idx..]) |arg| {
            try argList.appendSlice(std.mem.trim(u8, arg, " "));
            try argList.append(' ');
        }
        self.data = try argList.toOwnedSlice();
    }

    pub fn getCmd(self: Self, cmd: ?CmdName) Cmd {
        if (cmd == null) return self.rootCmd;
        for (self.subCmds) |value| {
            if (value.name == cmd) return value;
        }
        return self.rootCmd;
    }

    pub fn help(self: Self) !void {
        const padding = 20;
        const stdout = std.io.getStdOut().writer();
        if (self.description) |dis| {
            try stdout.print("Z Math {s}\n{s}\n\n", .{ self.version, dis });
        }
        const cmd_opt = self.cmd;
        try stdout.print("USAGE: \n", .{});
        try stdout.print("  {s}\n\n", .{cmd_opt.usage});
        try stdout.print("OPTIONS: \n", .{});
        if (cmd_opt.options) |opt| {
            for (opt) |value| {
                var opt_len: usize = 0;
                opt_len += value.short.len;
                try stdout.print(" {s},", .{value.short});

                opt_len += value.long.len;
                try stdout.print(" {s}", .{value.long});

                for (0..(padding - opt_len)) |_| {
                    try stdout.print(" ", .{});
                }
                try stdout.print("{s}\n", .{value.info});
            }
        }
        try stdout.print(" -h, --help          Help message.\n", .{});
        try stdout.print(" -v, --version       App version.\n", .{});
        try stdout.print("\n", .{});
        if (cmd_opt.name != .root) return;
        try stdout.print("COMMANDS: \n", .{});
        for (self.subCmds) |value| {
            if (value.info) |info| {
                const name = @tagName(value.name);
                try stdout.print(" {s}", .{name});
                for (0..(padding - name.len)) |_| {
                    try stdout.print(" ", .{});
                }
                try stdout.print("{s}\n", .{info});
            }
        }
    }
    pub fn deinit(self: *Self) void {
        self.computed_args.deinit();
        self.alloc.free(self.data);
    }
};
