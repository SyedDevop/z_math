const zarg = @import("zarg");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const MyCLiCmds = enum {
    root,
    length,
    area,
    history,
    delete,
    completion,
    volume,
    temp,
    config,

    pub fn getCmdNameList(alloc: Allocator) ![]const u8 {
        var result = std.ArrayList(u8).init(alloc);
        inline for (@typeInfo(MyCLiCmds).@"enum".fields) |field| {
            if (field.value == 0) continue;
            try result.appendSlice(field.name);
            try result.append(' ');
        }

        return result.toOwnedSlice(); // Return only the filled portion of the array
    }
};

pub const CmdType = zarg.Cmd(MyCLiCmds);

pub const myCLiCmdList = [_]CmdType{
    CmdType{
        .name = .root,
        .usage = "m [OPTIONS] \"EXPRESSION\"",
        .min_pos_arg = 1,
        .min_arg = 0,
        .print_help_for_min_pos_arg = true,
        .options = &.{
            .{
                .long = "--interactive",
                .short = "-i",
                .info = "Start interactive mode to evaluate expressions based on previous results.",
                .value = .{ .bool = null },
            },
            .{
                .long = "--inr",
                .short = "-i",
                .info = "Prints the number in Indian rupee formate.",
                .value = .{ .bool = false },
            },
            .{
                .long = "--word",
                .short = "-w",
                .info = "Prints the number in words.",
                .value = .{ .bool = null },
            },
            .{
                .long = "--raw",
                .short = "-r",
                .info = "Prints the raw result of the expression without any formatting.",
                .value = .{ .bool = null },
            },
        },
    },

    CmdType{
        .name = .length,
        .usage = "m lenght [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .example =
        \\Examples of Usage:
        \\    m length "mm:1:m"   - Converts 1 millimeter to meters.
        \\    m length "mm?1?m"   - Converts 1 millimeter to meters (with ? as a separator).
        \\    m length "mm 1 m"   - Converts 1 millimeter to meters.
        \\    m length "1 mm m"   - Converts 1 millimeter to meters.
        \\
        \\Notes:
        \\  - This command accepts any separator other than numbers or letters between units and values.
        \\  - The first unit specified is considered the starting unit (FROM_UNIT), and the last unit is the target (TO_UNIT).
        ,
        .info = "This command convert values between different units of length.",
        .options = &.{
            .{
                .long = "--unit",
                .short = "-u",
                .info = "Displays all the support units.",
                .value = .{ .bool = null },
            },
        },
    },
    CmdType{
        .name = .volume,
        .usage = "m volume [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .example =
        \\Notes:
        \\  - This command accepts any separator other than numbers or letters between units and values.
        \\  - The first unit specified is considered the starting unit (FROM_UNIT), and the last unit is the target (TO_UNIT).
        ,
        .info = "This command convert values between different units of volume.",
        .options = &.{
            .{
                .long = "--unit",
                .short = "-u",
                .info = "Displays all the support units.",
                .value = .{ .bool = null },
            },
        },
    },
    CmdType{
        .name = .temp,
        .usage = "m temp [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .example =
        \\Notes:
        \\  - This command accepts any separator other than numbers or letters between units and values.
        \\  - The first unit specified is considered the starting unit (FROM_UNIT), and the last unit is the target (TO_UNIT).
        ,
        .info = "This command convert values between different units of Temperature.",
        .options = &.{
            .{
                .long = "--unit",
                .short = "-u",
                .info = "Displays all the support units.",
                .value = .{ .bool = null },
            },
        },
    },
    CmdType{
        .name = .area,
        .usage = "m area [OPTIONS] \"FROM_UNIT:VALUE:TO_UNIT\"",
        .info = "This command convert values between different units of area.",
        .options = null,
    },
    CmdType{
        .name = .delete,
        .min_arg = 0,
        .usage = "m delete [ID] [OPTIONS]",
        .info = "This command delete the expressions for given [ID].",
        .options = &.{
            .{
                .long = "--all",
                .short = "-a",
                .info = "Delete all the entries.",
                .value = .{ .bool = false },
            },
            .{
                .long = "--range",
                .short = "-r",
                .info = "Delete range of the entries. |uasge: 10..15 |",
                .value = .{ .str = null },
            },
        },
    },
    CmdType{
        .name = .history,
        .min_arg = 0,
        .usage = "m history [OPTIONS] ",
        .info = "This command displays the history of previously evaluated expressions. By default, it shows the main history log.",
        .options = &.{
            .{
                .long = "--type",
                .short = "-t",
                .info = "Specifies the type of history to display. Options include: 'main', 'length' and 'area'. The default is . all",
                .value = .{ .str = null },
            },
            .{
                .long = "--all",
                .short = "-a",
                .info = "Display all the entries.",
                .value = .{ .bool = false },
            },
            .{
                .long = "--show-id",
                .short = "-id",
                .info = "Display Id for the entries.",
                .value = .{ .bool = false },
            },
            .{
                .long = "--earlier",
                .short = "-e",
                .info = "Display history entries from the earliest to the most recent. Defaults to showing recent entries.",
                .value = .{ .bool = false },
            },
            .{
                .long = "--limit",
                .short = "-l",
                .info = "Limit the number of history entries displayed. Default is 5.",
                .value = .{ .num = 5 },
            },
        },
    },
    CmdType{
        .name = .completion,
        .min_arg = 0,
        .usage = "m completion ",
        .info = "This command Generate the autocompletion script for gitpuller for the specified shell.",
        .options = null,
    },
    CmdType{
        .name = .config,
        .min_arg = 0,
        .usage = "m config [OPTIONS]",
        .info = "This command configurer you z_math.",
        .options = &.{
            .{
                .long = "--db-path",
                .short = "-dp",
                .info = "Print the dp path.",
                .value = .{ .bool = false },
            },
        },
    },
};
