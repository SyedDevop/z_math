const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Currency = enum {
    inr,
    usd,
    list,

    pub fn printAvailable(writer: anytype) !void {
        try writer.print("Available Currency:\n", .{});
        for (std.meta.fieldNames(Currency)) |crr| {
            if (std.mem.eql(u8, crr, "list")) continue;
            try writer.print("  - {s}\n", .{crr});
        }
    }
};

pub fn rate(alloc: Allocator, amount: f128, curr: Currency) !f128 {
    return 0;
}
