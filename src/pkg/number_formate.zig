const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn rupees(alloc: Allocator, n: f128) ![]u8 {
    const _rupees = try format(alloc, n, .rupees);
    return _rupees;
}

const FormatType = enum {
    number,
    rupees,
};
pub fn format(alloc: Allocator, n: f128, fmType: FormatType) ![]u8 {
    var num_fmt = std.ArrayList(u8).empty;

    const decimal: usize = @intFromFloat(@abs(n));
    const str_decimals = try std.fmt.allocPrint(alloc, "{d}", .{decimal});
    defer alloc.free(str_decimals);

    switch (fmType) {
        .rupees => try num_fmt.appendSlice(alloc, "₹"),
        .number => {},
    }
    if (n < 0.0) {
        try num_fmt.appendSlice(alloc, " -");
    }

    const str_decimals_len = str_decimals.len;
    for (str_decimals, 0..) |dig, i| {
        const remaining_digits = (str_decimals_len - i) -| 3; // the 3 is for thousand place
        if (i != 0 and remaining_digits % 2 == 0 and i <= str_decimals_len -| 3) {
            try num_fmt.append(alloc, ',');
        }
        try num_fmt.append(alloc, dig);
    }

    const fraction: f128 = @mod(n, 1);
    const fraction_number: usize = @intFromFloat(fraction * 100);
    try num_fmt.print(alloc, ".{d:0>2}", .{fraction_number});
    return num_fmt.toOwnedSlice(alloc);
}
// ```py python example for International numbers
// a = "1000000"
// for i, e in enumerate(a):
//     remaining_digits = len(a) - i
//     if i != 0 and remaining_digits % 3 == 0 and i <= len(a):
//         print(",", end="")
//     print(e, end="")
// ```
