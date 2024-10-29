const std = @import("std");

pub const Expr = struct {
    const Self = @This();

    id: i64,
    input: []const u8,
    output: []const u8,
    op_type: []const u8,
    execution_id: []const u8,
    created_at: []const u8,

    pub fn printStrExper(self: Self, is_id: ?bool) void {
        if (is_id != null and is_id == true) std.debug.print("({d}).\n", .{self.id});
        std.debug.print(" \x1b[0;36mThe input is :: {s} ::\x1b[0m\n", .{self.input});
        std.debug.print(" \x1b[3;21;32mAns: {s}\x1b[0m\n", .{self.output});
        std.debug.print("\n", .{});
    }

    pub fn destory(self: Self, alloc: std.mem.Allocator) void {
        alloc.free(self.input);
        alloc.free(self.output);
        alloc.free(self.op_type);
        alloc.free(self.execution_id);
        alloc.free(self.created_at);
    }
};
