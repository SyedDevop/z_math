const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CmdName = union(enum) { root: []const u8, len: []const u8, area: []const u8, history: []const u8 };

pub const Cmd = struct {
    name: CmdName,
    usage: []const u8,
    options: [][]const u8,
};

pub const Cli = struct {
    const Self = @This();

    args: std.process.ArgIterator,
    alloc: Allocator,
    cmds: Cmd,
    name: []const u8,
    description: ?[]const u8,
    pub fn init(allocate: Allocator, name: []const u8, description: ?[]const u8) Self {
        const args = try std.process.argsWithAllocator(allocate);
        return .{
            .alloc = allocate,
            .args = args,
            .name = name,
            .description = description,
        };
    }
    pub fn parse(self: *Self) !void {
        errdefer self.args.deinit();
    }
    pub fn deinit(self: *Self) void {
        self.args.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var cli = Cli.init(allocator);
    defer cli.deinit();

    std.debug.print("{any}", .{cli.cmds});
}
