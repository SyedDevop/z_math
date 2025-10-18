const Unit = @import("unit_object.zig");
const UnitMap = Unit.UnitMap;
const UnitValue = Unit.UnitsValue;

pub const massMap = UnitMap.initComptime(.{
    .{ "t", UnitValue{ .name = "Tonne", .v = 1000.0 } },
    .{ "kg", UnitValue{ .name = "Kilogram", .v = 1.0 } },
    .{ "g", UnitValue{ .name = "Gram", .v = 0.001 } },
    .{ "mg", UnitValue{ .name = "Milligram", .v = 1e-6 } },
    .{ "ug", UnitValue{ .name = "Microgram", .v = 1e-9 } },

    .{ "oz", UnitValue{ .name = "Ounce", .v = 0.028349523 } },
    .{ "lb", UnitValue{ .name = "Pound", .v = 0.45359237 } },
    .{ "st", UnitValue{ .name = "Ton (short ton)", .v = 907.18474 } },
});
