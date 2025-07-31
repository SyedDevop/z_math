const std = @import("std");

const WORDS = [28][]const u8{
    "Zero",     "One",      "Two",      "Three",   "Four",    "Five",
    "Six",      "Seven",    "Eight",    "Nine",    "Ten",     "Eleven",
    "Twelve",   "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
    "Eighteen", "Nineteen", "Twenty",   "Thirty",  "Forty",   "Fifty",
    "Sixty",    "Seventy",  "Eighty",   "Ninety",
};
const Writer = std.ArrayList(u8).Writer;
const NumErrors = error{NumberRangeNotSupported};
inline fn getWord(n: u8) []const u8 {
    return WORDS[if (n <= 20) n else (n / 10) + 18];
}

fn place2Word(n: u8, writer: Writer) !void {
    if (n < 20) {
        try writer.writeAll(getWord(n));
    } else if (n < 100) {
        try tenthWord(n, writer);
    }
}
fn tenthWord(n: u64, writer: Writer) !void {
    const tens = (n / 10) * 10;
    const ones = n % 10;
    try writer.writeAll(getWord(@intCast(tens)));
    if (ones > 0) try writer.print("-{s}", .{getWord(@intCast(ones))});
}

fn hundredthWord(n: u64, writer: Writer) !void {
    try writer.print("{s} Hundred ", .{getWord(@intCast(n / 100))});
    const tenth = n % 100;
    if (tenth > 0) try tenthWord(tenth, writer);
}

fn thousandthWord(n: u64, writer: Writer) !void {
    const thousandth: u8 = @intCast(n / 1000);
    try place2Word(thousandth, writer);
    try writer.writeAll(" Thousand ");
    const hundredth = n % 1000;
    if (hundredth > 0) try hundredthWord(hundredth, writer);
}
fn lakh_word(n: u64, writer: Writer) !void {
    const lakh: u8 = @intCast(n / 1_00_000);
    try place2Word(lakh, writer);
    try writer.writeAll(" Lakh ");
    try thousandthWord(n % 1_00_000, writer);
}

fn crore_word(n: u64, writer: Writer) !void {
    const crore: u8 = @intCast(n / 1_00_00_000);
    try place2Word(crore, writer);
    try writer.writeAll(" Crore ");
    try lakh_word(n % 1_00_00_000, writer);
}

fn toWords(n: u64, writer: Writer) !void {
    if (n < 100) {
        try place2Word(@intCast(n), writer);
    } else if (n < 1_000) {
        try hundredthWord(n, writer);
    } else if (n < 1_00_000) {
        try thousandthWord(n, writer);
    } else if (n < 1_00_00_000) {
        try lakh_word(n, writer);
    } else if (n < 1_00_00_00_000) {
        try crore_word(n, writer);
    } else return NumErrors.NumberRangeNotSupported;
}

/// You need to free the string after you are done using it.
pub fn numToWord(alloc: std.mem.Allocator, n: u64) ![]u8 {
    var num_word = std.ArrayList(u8).init(alloc);
    const writer = num_word.writer();
    try toWords(n, writer);
    return try num_word.toOwnedSlice();
}

/// You need to free the string after you are done using it.
pub fn floatToWord(alloc: std.mem.Allocator, n: f64) ![]u8 {
    var num_word = std.ArrayList(u8).init(alloc);
    const writer = num_word.writer();
    if (n < 0) try writer.print("(negative) ", .{});
    const whole_number: u64 = @intFromFloat(@abs(n));
    try toWords(whole_number, writer);
    try writer.print(" Point ", .{});

    const frac: f64 = @abs(n) - @as(f32, @floatFromInt(whole_number));
    const fracAsInt: u64 = @intFromFloat(frac * 100);
    try toWords(fracAsInt, writer);

    return try num_word.toOwnedSlice();
}

// pub fn main() !void {
//     const alloc = std.heap.page_allocator;
//     const num_word = try numToWord(alloc, 23);
//     std.debug.print("{s}\n", .{num_word});
// }
