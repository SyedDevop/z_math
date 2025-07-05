const std = @import("std");
const lexer = @import("../lexer.zig");

const Lexer = lexer.Lexer;

const TempType = enum {
    Celsius,
    Fahrenheit,
    Kelvin,
};
const Temperature = struct { name: TempType, v: f64 };
pub const tempMap = std.StaticStringMap(Temperature).initComptime(.{
    .{ "c", Temperature{ .name = .Celsius, .v = 1.0 } },
    .{ "f", Temperature{ .name = .Fahrenheit, .v = 33.8 } },
    .{ "k", Temperature{ .name = .Kelvin, .v = 273.15 } },
});

const Self = @This();
input: []const u8,
lex: *Lexer,
from: ?Temperature = null,
to: ?Temperature = null,
val: f64 = 0,
pub fn init(input: []const u8, lex: *Lexer) Self {
    return .{ .lex = lex, .input = input };
}
fn parse(self: *Self) !void {
    while (self.lex.hasTokes()) {
        const tok = try self.lex.nextToke();
        switch (tok) {
            .word => |w| {
                if (self.from == null) {
                    if (tempMap.get(w)) |v| {
                        self.from = v;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else if (self.to == null) {
                    if (tempMap.get(w)) |v| {
                        self.to = v;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else {
                    std.debug.print("[Error]: ({s}) No extra word can be provide.\n", .{w});
                    std.process.exit(1);
                }
            },
            .num => |n| self.val = n,
            else => {},
        }
    }
}
pub fn printUnits() void {
    std.debug.print("Available units:\n", .{});
    std.debug.print("Temperature's: ", .{});
    for (tempMap.keys()) |key| {
        std.debug.print("{s}, ", .{key});
    }
    std.debug.print("\n", .{});
    std.debug.print("Available units Name:\n", .{});
    std.debug.print("Name: ", .{});
    for (tempMap.values()) |val| {
        std.debug.print("{s}, ", .{@tagName(val.name)});
    }
    std.debug.print("\n", .{});
}

pub fn calculate(self: *Self) !f64 {
    try self.parse();
    const kelvin_v = switch (self.from.?.name) {
        .Celsius => self.val + 273.15,
        .Fahrenheit => (self.val - 32.0) * (5.0 / 9.0) + 273.15,
        .Kelvin => self.val,
    };

    const output = switch (self.to.?.name) {
        .Celsius => kelvin_v - 273.15,
        .Fahrenheit => (kelvin_v - 273.15) * (9.0 / 5.0) + 32.0,
        .Kelvin => kelvin_v,
    };
    std.debug.print(" \x1b[0;36mThe input is :: {s} ::\x1b[0m\n", .{self.input});
    std.debug.print(" \x1b[3;21;32mAns: {d} {s}\x1b[0m\n", .{ output, @tagName(self.to.?.name) });
    std.debug.print("\n", .{});
    return output;
}
