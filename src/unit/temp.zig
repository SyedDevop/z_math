const std = @import("std");
const Writer = std.Io.Writer;

const Lexer = @import("../lexer.zig");
const Unit = @import("unit_object.zig");
const UnitMap = Unit.UnitMap;
const UnitValue = Unit.UnitsValue;

const TempType = enum {
    Celsius,
    Fahrenheit,
    Kelvin,
};

pub const tempMap = UnitMap.initComptime(.{
    .{ "c", UnitValue{ .name = "Celsius", .v = 1.0 } },
    .{ "f", UnitValue{ .name = "Fahrenheit", .v = 33.8 } },
    .{ "k", UnitValue{ .name = "Kelvin", .v = 273.15 } },
});

const Self = @This();
unit: Unit,

pub fn init(input: []const u8, lex: *Lexer) Self {
    return .{ .unit = .init(input, lex, &tempMap) };
}

fn parse(self: *Self) !void {
    try self.unit.parse();
    if (self.unit.from == null) {
        self.unit.from = tempMap.get("f").?;
    }
    if (self.unit.to == null) {
        const from: UnitValue = self.unit.from orelse .{ .name = "", .v = 0 };
        const from_enum = std.meta.stringToEnum(TempType, from.name);
        self.unit.to = if (from_enum != null and from_enum.? == .Fahrenheit) tempMap.get("c").? else tempMap.get("f").?;
    }
}

pub fn printUnits(self: *const Self, w: *Writer) !void {
    return self.unit.printUnits(w, "Temperature's");
}

pub fn calculate(self: *Self, w: *Writer) !f64 {
    try self.parse();
    const from = std.meta.stringToEnum(TempType, self.unit.from.?.name) orelse return error.InvalidTemp;
    const to = std.meta.stringToEnum(TempType, self.unit.to.?.name) orelse return error.InvalidTemp;

    const kelvin_v = switch (from) {
        .Celsius => self.unit.val + 273.15,
        .Fahrenheit => (self.unit.val - 32.0) * (5.0 / 9.0) + 273.15,
        .Kelvin => self.unit.val,
    };

    const output = switch (to) {
        .Celsius => kelvin_v - 273.15,
        .Fahrenheit => (kelvin_v - 273.15) * (9.0 / 5.0) + 32.0,
        .Kelvin => kelvin_v,
    };

    try Unit.printOutput(self.unit.input, output, self.unit.to.?.name, w);
    return output;
}
