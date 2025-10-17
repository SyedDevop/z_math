const std = @import("std");
const Writer = std.io.Writer;
const Style = @import("zarg").Style;

const lexer = @import("../lexer.zig");

const Lexer = lexer.Lexer;

const MassUnit = struct { name: []const u8, v: f64 };

pub const massMap = std.StaticStringMap(MassUnit).initComptime(.{
    .{ "t", MassUnit{ .name = "Tonne", .v = 1000.0 } },
    .{ "kg", MassUnit{ .name = "Kilogram", .v = 1.0 } },
    .{ "g", MassUnit{ .name = "Gram", .v = 0.001 } },
    .{ "mg", MassUnit{ .name = "Milligram", .v = 1e-6 } },
    .{ "ug", MassUnit{ .name = "Microgram", .v = 1e-9 } },

    .{ "oz", MassUnit{ .name = "Ounce", .v = 0.028349523 } },
    .{ "lb", MassUnit{ .name = "Pound", .v = 0.45359237 } },
    .{ "st", MassUnit{ .name = "Ton (short ton)", .v = 907.18474 } },
});

const Mass = @This();
input: []const u8,
lex: *Lexer,
from: ?MassUnit = null,
to: ?MassUnit = null,
val: f64 = 0,

pub fn init(input: []const u8, lex: *Lexer) Mass {
    return .{ .lex = lex, .input = input };
}

fn parseMass(self: *Mass) !void {
    while (self.lex.hasTokes()) {
        const tok = try self.lex.nextToke();
        switch (tok) {
            .word => |w| {
                if (self.from == null) {
                    if (massMap.get(w)) |mass| {
                        self.from = mass;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else if (self.to == null) {
                    if (massMap.get(w)) |mass| {
                        self.to = mass;
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

pub fn printUnits(w: *Writer) !void {
    try w.print("Available units:\n", .{});
    try w.print("Mass: ", .{});
    for (massMap.keys()) |key| {
        try w.print("{s}, ", .{key});
    }
    try w.print("\n", .{});
    try w.print("Available units Name:\n", .{});
    try w.print("Name: ", .{});
    for (massMap.values()) |val| {
        try w.print("{s}, ", .{val.name});
    }
    try w.print("\n", .{});
}

pub fn calculateMass(self: *Mass, w: *Writer) !f64 {
    try self.parseMass();
    const output = self.val * (self.from.?.v / self.to.?.v);
    var style = Style{
        .fgColor = Style.Cyan,
    };
    try style.fmtRender("The input is :: {s} ::\n", .{self.input}, w);
    style.fgColor = Style.Green;
    style.fontStyle.doublyUnderline = true;

    try style.fmtRender("Ans: {d} {s}\n", .{ output, self.to.?.name }, w);
    return output;
}
