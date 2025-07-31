const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn formateToRupees(alloc: Allocator, n: f64) ![]u8 {
    var numbers = std.ArrayList(u8).init(alloc);
    defer numbers.deinit();
    var num_fmt = std.ArrayList(u8).init(alloc);
    var num_fmt_w = num_fmt.writer();

    const is_nagative = if (n < 0.0) true else false; // if (output_num < 0) {}
    const i_num: usize = @intFromFloat(@abs(n));
    const hundred: f64 = @mod(n, 1000); // @mod(output_num % 1000);
    var num: usize = i_num / 1000;
    while (num > 0) {
        if (num < 100) {
            try numbers.append(@truncate(num));
            break;
        }
        const new_num = num % 100;
        try numbers.append(@truncate(new_num));
        num = num / 100;
    }
    if (is_nagative) {
        try num_fmt.appendSlice("-₹ ");
    } else {
        try num_fmt.appendSlice("₹ ");
    }
    var i: usize = numbers.items.len - 1;
    while (i < numbers.items.len) : (i -%= 1) {
        const ns = numbers.items[i];
        if (ns < 10) try num_fmt_w.print("0", .{});
        try num_fmt_w.print("{d},", .{ns});
    }
    try num_fmt_w.print("{d:.2}", .{hundred});
    return num_fmt.toOwnedSlice();
}
