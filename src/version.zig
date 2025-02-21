const std = @import("std");
const build_option = @import("build_options");
const builtin = @import("builtin");
const sql = @cImport({
    @cInclude("sqlite3.h");
});

pub fn print() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{s} {s}\n\n", .{ build_option.name, build_option.version_string });
    try stdout.print("Version\n", .{});
    try stdout.print("  - version        : {s}\n", .{build_option.version_string});
    try stdout.print("  - git_hash       : {s}\n", .{build_option.git_hash});
    try stdout.print("  - git_hash_short : {s}\n", .{build_option.git_hash_short});
    try stdout.print("Build Config\n", .{});
    try stdout.print("  - Zig version    : {s}\n", .{builtin.zig_version_string});
    try stdout.print("  - build mode     : {}\n", .{builtin.mode});
    try stdout.print("  - Sqlite version : {s}\n", .{sql.sqlite3_version});
}
