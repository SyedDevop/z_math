const std = @import("std");
const NumWords = @import("num_words.zig");
const numToWord = NumWords.numToWord;

test "single digits" {
    const alloc = std.testing.allocator;

    const zero = try numToWord(alloc, 0);
    defer alloc.free(zero);
    try std.testing.expectEqualStrings("Zero", zero);

    const five = try numToWord(alloc, 5);
    defer alloc.free(five);
    try std.testing.expectEqualStrings("Five", five);
}
test "negative digits" {
    const alloc = std.testing.allocator;
    const zero = try numToWord(alloc, -156);
    defer alloc.free(zero);
    try std.testing.expectEqualStrings("(negative) One Hundred And Fifty Six", zero);
}

test "teens" {
    const alloc = std.testing.allocator;

    const eleven = try numToWord(alloc, 11);
    defer alloc.free(eleven);
    try std.testing.expectEqualStrings("Eleven", eleven);

    const nineteen = try numToWord(alloc, 19);
    defer alloc.free(nineteen);
    try std.testing.expectEqualStrings("Nineteen", nineteen);
}

test "tens" {
    const alloc = std.testing.allocator;

    const twenty = try numToWord(alloc, 20);
    defer alloc.free(twenty);
    try std.testing.expectEqualStrings("Twenty", twenty);

    const forty = try numToWord(alloc, 40);
    defer alloc.free(forty);
    try std.testing.expectEqualStrings("Forty", forty);
}

test "two digit numbers" {
    const alloc = std.testing.allocator;

    const twenty_one = try numToWord(alloc, 21);
    defer alloc.free(twenty_one);
    try std.testing.expectEqualStrings("Twenty One", twenty_one);

    const ninety_nine = try numToWord(alloc, 99);
    defer alloc.free(ninety_nine);
    try std.testing.expectEqualStrings("Ninety Nine", ninety_nine);
}

test "hundreds" {
    const alloc = std.testing.allocator;

    const one_hundred = try numToWord(alloc, 100);
    defer alloc.free(one_hundred);
    try std.testing.expectEqualStrings("One Hundred", one_hundred);

    const one_hundred_five = try numToWord(alloc, 105);
    defer alloc.free(one_hundred_five);
    try std.testing.expectEqualStrings("One Hundred And Five", one_hundred_five);

    const three_hundred_twenty = try numToWord(alloc, 320);
    defer alloc.free(three_hundred_twenty);
    try std.testing.expectEqualStrings("Three Hundred And Twenty", three_hundred_twenty);
}

test "thousands (Indian grouping)" {
    const alloc = std.testing.allocator;

    const one_thousand = try numToWord(alloc, 1000);
    defer alloc.free(one_thousand);
    try std.testing.expectEqualStrings("One Thousand", one_thousand);

    const twelve_thousand = try numToWord(alloc, 12000);
    defer alloc.free(twelve_thousand);
    try std.testing.expectEqualStrings("Twelve Thousand", twelve_thousand);

    const one_thousand_twenty = try numToWord(alloc, 1020);
    defer alloc.free(one_thousand_twenty);
    try std.testing.expectEqualStrings("One Thousand Twenty", one_thousand_twenty);
}

test "lakhs and crores" {
    const alloc = std.testing.allocator;

    const one_lakh = try numToWord(alloc, 100000);
    defer alloc.free(one_lakh);
    try std.testing.expectEqualStrings("One Lakh", one_lakh);

    const one_crore = try numToWord(alloc, 10000000);
    defer alloc.free(one_crore);
    try std.testing.expectEqualStrings("One Crore", one_crore);

    const complex = try numToWord(alloc, 12345678);
    defer alloc.free(complex);
    try std.testing.expectEqualStrings(
        "One Crore Twenty Three Lakh Forty Five Thousand Six Hundred And Seventy Eight",
        complex,
    );
}
