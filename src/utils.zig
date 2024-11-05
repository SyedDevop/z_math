const std = @import("std");

pub fn parseUintBase10(comptime T: type, buf: ?[]const u8) !T {
    const num: u64 = if (buf) |n| std.fmt.parseUnsigned(T, n, 10) catch |e| switch (e) {
        error.InvalidCharacter => 0,
        else => return e,
    } else 0;
    return num;
}
