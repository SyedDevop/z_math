const std = @import("std");
const lexer = @import("../lexer.zig");

const Lexer = lexer.Lexer;

const Volume = struct { name: []const u8, v: f64 };

pub const volMap = std.StaticStringMap(Volume).initComptime(.{
    .{ "l", .{ .name = "Liter", .v = 1.0 } },
    .{ "ml", .{ .name = "Milliliter", .v = 0.001 } },
    .{ "floz", .{ .name = "FluidOunce", .v = 0.0295735295625 } },
    .{ "gal", .{ .name = "Gallon", .v = 3.785411784 } },
    .{ "qt", .{ .name = "Quart", .v = 0.946352946 } },
    .{ "pt", .{ .name = "Pint", .v = 0.473176473 } },
    .{ "gil", .{ .name = "Gil", .v = 0.118294118 } },
});

const Self = @This();
input: []const u8,
lex: *Lexer,
from: ?Volume = null,
to: ?Volume = null,
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
                    if (volMap.get(w)) |v| {
                        self.from = v;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else if (self.to == null) {
                    if (volMap.get(w)) |v| {
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
    std.debug.print("Volumes: ", .{});
    for (volMap.keys()) |key| {
        std.debug.print("{s}, ", .{key});
    }
    std.debug.print("\n", .{});
    std.debug.print("Available units Name:\n", .{});
    std.debug.print("Name: ", .{});
    for (volMap.values()) |val| {
        std.debug.print("{s}, ", .{val.name});
    }
    std.debug.print("\n", .{});
}

pub fn calculate(self: *Self) !f64 {
    try self.parse();
    const output = (self.val * self.from.?.v) / self.to.?.v;
    std.debug.print(" \x1b[0;36mThe input is :: {s} ::\x1b[0m\n", .{self.input});
    std.debug.print(" \x1b[3;21;32mAns: {d} {s}\x1b[0m\n", .{ output, self.to.?.name });
    std.debug.print("\n", .{});
    return output;
}
