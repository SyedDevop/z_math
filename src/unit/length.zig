const Unit = @import("unit_object.zig");
const UnitMap = Unit.UnitMap;
const UnitValue = Unit.UnitsValue;

pub const LENGTH_MAP = UnitMap.initComptime(.{
    .{ "mm", UnitValue{ .name = "Millimeter", .v = 0.001 } },
    .{ "cm", UnitValue{ .name = "Centimeter", .v = 0.01 } },
    .{ "m", UnitValue{ .name = "Meter", .v = 1.0 } },
    .{ "km", UnitValue{ .name = "Kilometer", .v = 1000.0 } },
    .{ "ft", UnitValue{ .name = "Feet", .v = 0.3047 } },
    .{ "hc", UnitValue{ .name = "Hectometer", .v = 100.0 } },
    .{ "dam", UnitValue{ .name = "Decameter", .v = 10.0 } },
    .{ "dm", UnitValue{ .name = "Decimeter", .v = 0.1 } },
    .{ "in", UnitValue{ .name = "Inch", .v = 0.0254 } },
    .{ "yd", UnitValue{ .name = "Yard", .v = 0.9114 } },
    .{ "mi", UnitValue{ .name = "Mile", .v = 1609.344 } },
    .{ "nmi", UnitValue{ .name = "Nautical mile", .v = 1853.184 } },
});
