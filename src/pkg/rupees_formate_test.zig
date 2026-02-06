const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const rupees_formate = @import("rupees_formate.zig");

test "formateToRupees - basic positive numbers" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 0.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹0.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 1.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹1.00", result2);

    const result3 = try rupees_formate.formateToRupees(alloc, 10.0);
    defer alloc.free(result3);
    try testing.expectEqualStrings("₹10.00", result3);

    const result4 = try rupees_formate.formateToRupees(alloc, 10.4);
    defer alloc.free(result4);
    try testing.expectEqualStrings("₹10.40", result4);
}

test "formateToRupees - only fraction" {
    const alloc = testing.allocator;

    const result = try rupees_formate.formateToRupees(alloc, 0.99);
    defer alloc.free(result);

    try testing.expectEqualStrings("₹0.99", result);
}

test "formateToRupees - thousands format" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 1000.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹1,000.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 10000.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹10,000.00", result2);
}

test "formateToRupees - lakhs format" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 100000.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹1,00,000.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 250000.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹2,50,000.00", result2);
}

test "formateToRupees - crores format" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 10000000.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹1,00,00,000.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 12345678.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹1,23,45,678.00", result2);
}

test "formateToRupees - negative numbers" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, -1.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹ -1.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, -100000.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹ -1,00,000.00", result2);
}

test "formateToRupees - decimal numbers" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 123.45);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹123.45", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 1234.56);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹1,234.55", result2);
}

test "formateToRupees - large numbers" {
    const alloc = testing.allocator;

    const result1 = try rupees_formate.formateToRupees(alloc, 1000000000.0);
    defer alloc.free(result1);
    try testing.expectEqualStrings("₹1,00,00,00,000.00", result1);

    const result2 = try rupees_formate.formateToRupees(alloc, 9876543210.0);
    defer alloc.free(result2);
    try testing.expectEqualStrings("₹9,87,65,43,210.00", result2);
}
