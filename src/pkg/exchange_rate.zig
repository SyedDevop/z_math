const std = @import("std");
const Allocator = std.mem.Allocator;

const http = std.http;

var curr_array = std.EnumArray(Currency, []const u8).initDefault(null, .{
    .aed = "United Arab Emirates Dirham",
    .aud = "Australian Dollar",
    .btc = "Bitcoin",
    .cnh = "Chinese Yuan Renminbi Offshore",
    .cny = "Chinese Yuan Renminbi",
    .etc = "Ethereum Classic",
    .eth = "Ethereum",
    .eur = "Euro",
    .gbp = "British Pound",
    .inr = "Indian Rupee",
    .jpy = "Japanese Yen",
    .qar = "Qatari Riyal",
    .sar = "Saudi Arabian Riyal",
    .usd = "US Dollar",
    .list = "List",
});
pub const Currency = enum {
    aed,
    aud,
    btc,
    cnh,
    cny,
    etc,
    eth,
    eur,
    gbp,
    inr,
    jpy,
    qar,
    sar,
    usd,
    list,

    pub fn printAvailable(writer: anytype) !void {
        try writer.print("=== Available Currencies ===\n\n", .{});
        try writer.print("{s:^5} | {s}\n", .{ "Cur", "Decoration" });
        try writer.print("-------------------------------\n", .{});
        var it = curr_array.iterator();
        while (it.next()) |crr| {
            if (crr.key == .list) continue;
            try writer.print("{s:^5} | '{s}'\n", .{ @tagName(crr.key), crr.value.* });
        }
    }
};
// eur.json
const ONE_KB = 1024;
const TWO_KB = ONE_KB * 2;
const EIGHT_KB = ONE_KB * 8;

fn generateUrl(alloc: Allocator, curr: Currency) ![]u8 {
    return try std.fmt.allocPrint(alloc, "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{s}.min.json", .{@tagName(curr)});
}
pub fn rate(alloc: Allocator, amount: f128, from_curr: Currency, to_curr: Currency) !f128 {
    std.debug.print("[Info]: from_curr({s}) to_curr({s})\n", .{ @tagName(from_curr), @tagName(to_curr) });
    var arena = std.heap.ArenaAllocator.init(alloc);
    const arena_alloc = arena.allocator();
    defer arena.deinit();

    var client = http.Client{ .allocator = arena_alloc };
    defer client.deinit();

    const url = try generateUrl(arena_alloc, from_curr);

    const uri = try std.Uri.parse(url);
    var buf: [TWO_KB]u8 = undefined;
    var req = try client.open(.GET, uri, .{ .server_header_buffer = &buf });
    defer req.deinit();
    try req.send();
    try req.finish();
    try req.wait();

    var jws = std.json.reader(alloc, req.reader());
    defer jws.deinit();

    const va = try std.json.Value.jsonParse(arena_alloc, &jws, .{ .max_value_len = EIGHT_KB });
    return switch (va) {
        .object => |*obj| {
            const keys = obj.keys();
            if (keys.len < 2) return error.CurrencyNotFound;
            switch (obj.get(keys[1]).?) {
                .object => |*curr_obj| {
                    const inr: f64 = switch (curr_obj.get(@tagName(to_curr)).?) {
                        .float => |f| f,
                        .integer => |i| @floatFromInt(i),
                        else => 0.0,
                    };
                    return inr * amount;
                },
                else => return error.InvalidCurrJSON,
            }
        },
        else => return error.InvalidJSON,
    };
}
