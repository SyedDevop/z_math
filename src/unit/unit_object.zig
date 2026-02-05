const std = @import("std");
const Writer = std.io.Writer;

const Lexer = @import("../lexer.zig");

pub const UnitsValue = struct { name: []const u8, v: f64 };
pub const UnitMap = std.StaticStringMap(UnitsValue);

const Unit = @This();
input: []const u8,
lex: *Lexer,
from: ?UnitsValue = null,
to: ?UnitsValue = null,
val: f64 = 0,

unitMap: *const UnitMap = undefined,

pub fn init(input: []const u8, lex: *Lexer, unitMap: *const UnitMap) Unit {
    return .{ .lex = lex, .input = input, .unitMap = unitMap };
}

pub fn parse(self: *Unit) !void {
    while (self.lex.hasTokes()) {
        const tok = try self.lex.nextToke();
        switch (tok) {
            .word => |w| {
                if (self.from == null) {
                    if (self.unitMap.get(w)) |u| {
                        self.from = u;
                    } else {
                        std.debug.print("[Error]: ({s}) is not a know unit.\n", .{w});
                        std.process.exit(1);
                    }
                } else if (self.to == null) {
                    if (self.unitMap.get(w)) |u| {
                        self.to = u;
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

pub fn printUnits(self: *const Unit, w: *Writer, unitName: []const u8) !void {
    try w.print("Available units:\n", .{});
    try w.print("{s}: ", .{unitName});
    for (self.unitMap.keys()) |key| {
        try w.print("{s}, ", .{key});
    }
    try w.print("\n", .{});
    try w.print("Available units Name:\n", .{});
    try w.print("Name: ", .{});
    for (self.unitMap.values()) |val| {
        try w.print("{s}, ", .{val.name});
    }
    try w.print("\n", .{});
}

const Style = @import("zarg").Style;

pub fn calculate(self: *Unit, w: *Writer) !f64 {
    try self.parse();
    const output = self.val * (self.from.?.v / self.to.?.v);
    try printOutput(self.input, output, self.to.?.name, w);
    return output;
}

pub fn calculate2(self: *Unit, w: *Writer) !f64 {
    try self.parse();
    const output = (self.val * self.from.?.v) / self.to.?.v;
    try printOutput(self.input, output, self.to.?.name, w);
    return output;
}

pub fn printOutput(input: []const u8, output: f64, output_type_name: []const u8, w: *Writer) !void {
    var style = Style{
        .fgColor = Style.Cyan,
    };
    try style.fmtRender("The input is :: {s} ::\n", .{input}, w);
    style.fgColor = Style.Green;
    style.fontStyle.doublyUnderline = true;

    try style.fmtRender("Ans: {d} {s}\n", .{ output, output_type_name }, w);
}
