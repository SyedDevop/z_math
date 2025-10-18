const Unit = @import("unit_object.zig");
const UnitMap = Unit.UnitMap;
const UnitValue = Unit.UnitsValue;

pub const volMap = UnitMap.initComptime(.{
    .{ "l", UnitValue{ .name = "Liter", .v = 1.0 } },
    .{ "ml", UnitValue{ .name = "Milliliter", .v = 0.001 } },
    .{ "floz", UnitValue{ .name = "FluidOunce", .v = 0.0295735295625 } },
    .{ "gal", UnitValue{ .name = "Gallon", .v = 3.785411784 } },
    .{ "qt", UnitValue{ .name = "Quart", .v = 0.946352946 } },
    .{ "pt", UnitValue{ .name = "Pint", .v = 0.473176473 } },
    .{ "gil", UnitValue{ .name = "Gil", .v = 0.118294118 } },
});
