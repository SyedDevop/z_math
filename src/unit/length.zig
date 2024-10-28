const std = @import("std");
const lexer = @import("../lexer.zig");

const Lexer = lexer.Lexer;

const Lenght = struct { name: []const u8, v: f64 };

pub const lenghtMap = std.StaticStringMap(Lenght).initComptime(.{
    .{ "mm", .{ .name = "Millimeter", .v = 0.001 } },
    .{ "cm", .{ .name = "Centimeter", .v = 0.01 } },
    .{ "m", .{ .name = "Meter", .v = 1.0 } },
    .{ "km", .{ .name = "Kilometer", .v = 1000.0 } },
    .{ "ft", .{ .name = "Feet", .v = 0.3047 } },
    .{ "hc", .{ .name = "Hectometer", .v = 100.0 } },
    .{ "dam", .{ .name = "Decameter", .v = 10.0 } },
    .{ "dm", .{ .name = "Decimeter", .v = 0.1 } },
    .{ "in", .{ .name = "Inch", .v = 0.0254 } },
    .{ "yd", .{ .name = "Yard", .v = 0.9114 } },
    .{ "mi", .{ .name = "Mile", .v = 1609.344 } },
    .{ "nmi", .{ .name = "Nautical mile", .v = 1853.184 } },
});

const Self = @This();
input: []const u8,
lex: *Lexer,
from: ?Lenght = null,
to: ?Lenght = null,
val: f64 = 0,
pub fn init(input: []const u8, lex: *Lexer) Self {
    return .{ .lex = lex, .input = input };
}

fn parseLength(self: *Self) !void {
    while (self.lex.hasTokes()) {
        const tok = try self.lex.nextToke();
        switch (tok) {
            .word => |w| {
                if (self.from == null) {
                    if (lenghtMap.get(w)) |lenght| {
                        self.from = lenght;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else if (self.to == null) {
                    if (lenghtMap.get(w)) |lenght| {
                        self.to = lenght;
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
    std.debug.print("Length: ", .{});
    for (lenghtMap.keys()) |key| {
        std.debug.print("{s}, ", .{key});
    }
    std.debug.print("\n", .{});
    std.debug.print("Available units Name:\n", .{});
    std.debug.print("Name: ", .{});
    for (lenghtMap.values()) |val| {
        std.debug.print("{s}, ", .{val.name});
    }
    std.debug.print("\n", .{});
}

pub fn calculateLenght(self: *Self) !f64 {
    try self.parseLength();
    const output = self.val * (self.from.?.v / self.to.?.v);
    std.debug.print(" \x1b[0;36mThe input is :: {s} ::\x1b[0m\n", .{self.input});
    std.debug.print(" \x1b[3;21;32mAns: {d} {s}\x1b[0m\n", .{ output, self.to.?.name });
    std.debug.print("\n", .{});
    return output;
}
