const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn formateToRupees(alloc: Allocator, n: f128) ![]u8 {
    var num_fmt = std.ArrayList(u8).empty;
    var num_fmt_w = num_fmt.writer(alloc);

    const decimal: usize = @intFromFloat(@abs(n));
    const str_decimals = try std.fmt.allocPrint(alloc, "{d}", .{decimal});
    defer alloc.free(str_decimals);

    try num_fmt.appendSlice(alloc, "₹");
    if (n < 0.0) {
        try num_fmt_w.writeAll(" -");
    }

    const str_decimals_len = str_decimals.len;
    for (str_decimals, 0..) |dig, i| {
        const remaining_digits = (str_decimals_len - i) -| 3; // the 3 is for thousand place
        if (i != 0 and remaining_digits % 2 == 0 and i <= str_decimals_len -| 3) {
            try num_fmt_w.writeByte(',');
        }
        try num_fmt_w.writeByte(dig);
    }

    const fraction: f128 = @mod(n, 1);
    const fraction_number: usize = @intFromFloat(fraction * 1000);
    try num_fmt_w.print(".{d:0>2}", .{fraction_number});
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
