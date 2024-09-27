const std = @import("std");
pub const Token = union(enum) {
    num: f64,
    operator: u8,
    function: []const u8,

    illegal: struct {
        st_pos: usize,
        en_pos: usize,
    },

    // add,
    // sub,
    // mul,
    // div,
    // negate: u8,
    // id: u8,

    mm,
    cm,
    m,
    km,
    in,
    ft,

    colon,
    lparen,
    rparen,
    lsquirly,
    rsquirly,

    less_than,
    greater_than,

    equal,
    not_equal,

    eof,
    pub fn keyword(key: []const u8) ?Token {
        const map = std.StaticStringMap(Token).initComptime(.{
            .{ "tan", .{ .function = "tan" } },
            .{ "sine", .{ .function = "sine" } },
            .{ "cost", .{ .function = "cost" } },
            .{ "mm", .mm },
            .{ "cm", .cm },
            .{ "m", .m },
            .{ "km", .km },
            .{ "ft", .ft },
            .{ "in", .in },
        });
        return map.get(key);
    }

    pub fn toString(self: Token, writer: anytype) !void {
        switch (self) {
            .num => |n| {
                try std.fmt.formatInt(n, 10, std.fmt.Case.lower, .{}, writer);
            },
            .operator => |o| try std.fmt.format(writer, "{c}", .{o}),

            .lparen => try std.fmt.format(writer, "(", .{}),
            .rparen => try std.fmt.format(writer, ")", .{}),
            .mm => try std.fmt.formate(writer, "Mil", .{}),
            .cm => try std.fmt.formate(writer, "Cm", .{}),
            .m => try std.fmt.formate(writer, "M", .{}),
            .km => try std.fmt.formate(writer, "Km", .{}),
            .in => try std.fmt.formate(writer, "in", .{}),
            .ft => try std.fmt.formate(writer, "Ft", .{}),
            else => {},
        }
    }
    pub fn getCharNum(self: Token) ?f64 {
        return switch (self) {
            .num => |n| n,
            else => null,
        };
    }
    pub fn getCharOprater(self: Token) ?u8 {
        return switch (self) {
            .operator => |o| o,
            else => null,
        };
    }
    pub fn isOprater(self: Token, ch: u8) bool {
        return switch (self) {
            .operator => |op| ch == op,
            else => false,
        };
    }

    pub fn arryToString(tokens: []Token) ![]const u8 {
        var list = std.ArrayList(u8).init(std.heap.page_allocator);
        defer list.deinit();

        for (tokens) |tok| {
            try tok.toString(list.writer());
            try list.appendSlice(" ");
        }
        return try list.toOwnedSlice();
    }
};
