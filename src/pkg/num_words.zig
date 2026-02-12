// setlocal makeprg=zig\ build-exe\ %
const std = @import("std");
const Writer = std.Io.Writer;

const WORDS = [28][]const u8{
    "Zero",     "One",      "Two",      "Three",   "Four",    "Five",
    "Six",      "Seven",    "Eight",    "Nine",    "Ten",     "Eleven",
    "Twelve",   "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
    "Eighteen", "Nineteen", "Twenty",   "Thirty",  "Forty",   "Fifty",
    "Sixty",    "Seventy",  "Eighty",   "Ninety",
};

const MAGNITUDES: []const []const u8 = &.{
    "",     "Thousand", "Lakh", "Crore",
    "Arab", "Kharab",   "Neel", "Padma",
};

inline fn getWord(n: usize) []const u8 {
    std.debug.assert(n < 100);
    return WORDS[if (n <= 20) n else (n / 10) + 18];
}

fn subThousand(n: usize, writer: *Writer) !void {
    std.debug.assert(n < 1000);
    var it: usize = n;

    while (true) {
        if (it < 100) {
            try writer.writeAll(getWord(it));
        } else {
            try writer.print("{s} Hundred", .{getWord(it / 100)});
            if (it % 100 > 0) try writer.writeAll(" And");
        }
        try writer.writeByte(' ');

        if (it < 20) {
            break;
        } else if (it < 100) {
            it %= 10;
        } else {
            it %= 100;
        }

        if (it == 0) break;
    }
}

fn toWords(n: usize, writer: *Writer) !void {
    if (n == 0) {
        try writer.writeAll(getWord(n));
        return;
    }
    var parts: [10]usize = @splat(0);
    var count: usize = 0;
    var value = n;

    // First group (last 3 digits)
    parts[count] = value % 1000;
    value /= 1000;
    count += 1;

    while (value > 0) {
        parts[count] = value % 100;
        value /= 100;
        count += 1;
    }

    var i: isize = @intCast(count);
    i -= 1;
    while (i >= 0) : (i -= 1) {
        const idx: usize = @intCast(i);
        const part = parts[idx];
        if (part == 0) continue;

        try subThousand(part, writer);

        if (idx > MAGNITUDES.len and idx == 0) continue;
        try writer.writeAll(MAGNITUDES[idx]);
        try writer.writeByte(' ');
    }
}

/// You need to free the string after you are done using it.
pub fn numToWord(alloc: std.mem.Allocator, n: usize) ![]u8 {
    var alloc_writer: std.Io.Writer.Allocating = try .initCapacity(alloc, 1024);
    defer alloc_writer.deinit();

    try toWords(n, &alloc_writer.writer);

    const word_clean = std.mem.trim(u8, alloc_writer.written(), " ");
    return alloc.dupe(u8, word_clean);
}
