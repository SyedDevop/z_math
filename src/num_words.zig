const std = @import("std");

const WORDS = [28][]const u8{
    "Zero",     "One",      "Two",      "Three",   "Four",    "Five",
    "Six",      "Seven",    "Eight",    "Nine",    "Ten",     "Eleven",
    "Twelve",   "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
    "Eighteen", "Nineteen", "Twenty",   "Thirty",  "Forty",   "Fifty",
    "Sixty",    "Seventy",  "Eighty",   "Ninety",
};
const Writer = std.ArrayList(u8).Writer;

inline fn getWord(n: u8) []const u8 {
    return WORDS[if (n <= 20) n else (n / 10) + 18];
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

fn numToWord(alloc: std.mem.Allocator, n: u64) ![]u8 {
    var num_word = std.ArrayList(u8).init(alloc);
    var writer = num_word.writer();

    if (n < 20) {
        try num_word.appendSlice(getWord(@intCast(n)));
        return try num_word.toOwnedSlice();
    }
    if (n < 100) {
        try tenthWord(n, writer);
        return try num_word.toOwnedSlice();
    }

    if (n < 1000) {
        try hundredthWord(n, writer);
        return try num_word.toOwnedSlice();
    }

    if (n < 1_00_000) {
        try writer.print("{s} Thousand ", .{getWord(@intCast(n / 1000))});
        const hundredth = n % 1000;
        if (hundredth > 0) try hundredthWord(hundredth, writer);
        return try num_word.toOwnedSlice();
    }
    return try num_word.toOwnedSlice();
}
pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const num_word = try numToWord(alloc, 99999);
    std.debug.print("{s}\n", .{num_word});
}
