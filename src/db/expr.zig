const std = @import("std");

pub const Expr = struct {
    const Self = @This();

    id: i64,
    input: []const u8,
    output: []const u8,
    execution_id: []const u8,
    created_at: []const u8,

    pub fn destory(self: Self, alloc: std.mem.Allocator) void {
        alloc.free(self.input);
        alloc.free(self.output);
        alloc.free(self.execution_id);
        alloc.free(self.created_at);
    }
};
