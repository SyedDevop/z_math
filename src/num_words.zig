const std = @import("std");
const Allocator = std.mem.Allocator;

const WORDS = [28][]const u8{
    "Zero",     "One",      "Two",      "Three",   "Four",    "Five",
    "Six",      "Seven",    "Eight",    "Nine",    "Ten",     "Eleven",
    "Twelve",   "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
    "Eighteen", "Nineteen", "Twenty",   "Thirty",  "Forty",   "Fifty",
    "Sixty",    "Seventy",  "Eighty",   "Ninety",
};
const NUMBER_POSITION_LEN = 4;
const NUMBER_POSITION = [NUMBER_POSITION_LEN][]const u8{
    "Hundred", "Thousand",
    "Lakh",    "Crore",
};
//
// const Writer = std.ArrayList([]u8).Writer;
// const NumErrors = error{NumberRangeNotSupported};
// inline fn getWord(n: u8) []const u8 {
//     return WORDS[if (n <= 20) n else (n / 10) + 18];
// }
//
// fn place2Word(n: u8, writer: Writer) !void {
//     if (n < 20) {
//         try writer.writeAll(getWord(n));
//     } else if (n < 100) {
//         try tenthWord(n, writer);
//     }
// }
// fn tenthWord(n: u128, writer: Writer) !void {
//     const tens = (n / 10) * 10;
//     const ones = n % 10;
//     try writer.writeAll(getWord(@intCast(tens)));
//     if (ones > 0) try writer.print("-{s}", .{getWord(@intCast(ones))});
// }
//
// fn hundredthWord(n: u128, writer: Writer) !void {
//     try writer.print("{s} Hundred ", .{getWord(@intCast(n / 100))});
//     const tenth = n % 100;
//     if (tenth > 0) try tenthWord(tenth, writer);
// }
//
// fn thousandthWord(n: u128, writer: Writer) !void {
//     const thousandth: u8 = @intCast(n / 1000);
//     try place2Word(thousandth, writer);
//     try writer.writeAll(" Thousand ");
//     const hundredth = n % 1000;
//     if (hundredth > 0) try hundredthWord(hundredth, writer);
// }
// fn lakh_word(n: u128, writer: Writer) !void {
//     const lakh: u8 = @intCast(n / 1_00_000);
//     try place2Word(lakh, writer);
//     try writer.writeAll(" Lakh ");
//     try thousandthWord(n % 1_00_000, writer);
// }
//
// fn crore_word(n: u128, writer: Writer) !void {
//     const crore: u8 = @intCast(n / 1_00_00_000);
//     try place2Word(crore, writer);
//     try writer.writeAll(" Crore ");
//     try lakh_word(n % 1_00_00_000, writer);
// }
//
// fn toWords(n: u128, alloc: Allocator) !void {
//     var numbers = std.ArrayList(u8).init(alloc);
//     defer numbers.deinit();
//     var num_fmt = std.ArrayList([]u8).init(alloc);
//     const num_fmt_w = num_fmt.writer();
//     const i_num: u128 = @abs(n);
//     const hundred: u128 = @mod(n, 1000); // @mod(output_num % 1000);
//     var num: u128 = i_num / 1000;
//     _ = hundred;
//     // _ = num_fmt_w;
//     var i: usize = 1;
//     while (num > 0) : (i = i % NUMBER_POSITION_LEN + 1) {
//         // std.debug.print("I {d}", .{i - 1});
//
//         const new_num = @mod(num, 100);
//         try place2Word(@truncate(new_num), num_fmt_w);
//         try num_fmt_w.print(" {s}", .{NUMBER_POSITION[i -| 1]});
//         num = num / 100;
//     }
//
//     var a: usize = num_fmt.items.len - 1;
//     while (a < num_fmt.items.len) : (a -%= 1) {
//         const ns = num_fmt.items[a];
//         std.debug.print("{s} ", .{ns});
//     }
//     // if (n < 100) {
//     //     try place2Word(@intCast(n), writer);
//     // } else if (n < 1_000) {
//     //     try hundredthWord(n, writer);
//     // } else if (n < 1_00_000) {
//     //     try thousandthWord(n, writer);
//     // } else if (n < 1_00_00_000) {
//     //     try lakh_word(n, writer);
//     // } else if (n < 1_00_00_00_000) {
//     //     try crore_word(n, writer);
//     // } else return NumErrors.NumberRangeNotSupported;
// }

/// You need to free the string after you are done using it.
// pub fn numToWord(alloc: std.mem.Allocator, n: u128) ![]u8 {
//     var num_word = std.ArrayList(u8).init(alloc);
//     const writer = num_word.writer();
//     try toWords(n, writer);
//     return try num_word.toOwnedSlice();
// }

/// You need to free the string after you are done using it.
pub fn floatToWord(alloc: std.mem.Allocator, n: f128) ![]u8 {
    var num_word = std.ArrayList(u8).init(alloc);
    _ = n;
    // const writer = num_word.writer();
    // if (n < 0) try writer.print("(negative) ", .{});
    // const whole_number: u128 = @intFromFloat(@abs(n));
    // try toWords(whole_number, alloc);
    // try writer.print(" Point ", .{});
    //
    // const frac: f128 = @abs(n) - @as(f128, @floatFromInt(whole_number));
    // const fracAsInt: u128 = @intFromFloat(frac * 100);
    // try toWords(fracAsInt, writer);

    return try num_word.toOwnedSlice();
}

// pub fn main() !void {
//     const alloc = std.heap.page_allocator;
//     const num_word = try toWords(99_99_99_99_99_99_999, alloc);
//     _ = num_word;
//     // std.debug.print("{s}\n", .{num_word});
// }
