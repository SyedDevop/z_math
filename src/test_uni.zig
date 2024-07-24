const std = @import("std");

pub const NodeType = enum {
    tip,
    node,
};

pub const Tip = struct {
    fn toString(_: Tip, allocator: std.mem.Allocator) []const u8 {
        return allocator.dupe(u8, "Tip") catch unreachable;
    }
};

pub const leaf = Tip{};

pub const Node = struct {
    left: *const Tree,
    value: u32,
    right: *const Tree,

    pub fn toString(self: Node, allocator: std.mem.Allocator) []const u8 {
        const left = self.left.toString(allocator);
        defer allocator.free(left);
        const right = self.right.toString(allocator);
        defer allocator.free(right);
        return std.fmt.allocPrint(allocator, "Node ({s} {d} {s})", .{ left, self.value, right }) catch unreachable;
    }
};

// etree = Node (Node (Node Tip 1 Tip) 3 (Node Tip 4 Tip)) 5 (Node Tip 7 Tip)
pub const Tree = union(NodeType) {
    tip: Tip,
    node: *const Node,

    pub fn toString(self: Tree, allocator: std.mem.Allocator) []const u8 {
        return switch (self) {
            .tip => |t| t.toString(allocator),
            .node => |n| n.toString(allocator),
        };
    }
};

test "adt" {
    const tree = Tree{
        .node = &Node{
            .left = &Tree{
                .node = &Node{
                    .left = &Tree{
                        .node = &Node{
                            .left = &Tree{ .tip = leaf },
                            .value = 1,
                            .right = &Tree{ .tip = leaf },
                        },
                    },
                    .value = 3,
                    .right = &Tree{
                        .node = &Node{
                            .left = &Tree{ .tip = leaf },
                            .value = 4,
                            .right = &Tree{ .tip = leaf },
                        },
                    },
                },
            },
            .value = 5,
            .right = &Tree{
                .node = &Node{
                    .left = &Tree{ .tip = leaf },
                    .value = 7,
                    .right = &Tree{ .tip = leaf },
                },
            },
        },
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};

    {
        var allocator = gpa.allocator();
        std.debug.print("adt tree = {}\n", .{tree});
        const tree_string = tree.toString(allocator);
        defer allocator.free(tree_string);
        std.debug.print("adt tree printed = {s}\n", .{tree_string});

        try std.testing.expect(std.mem.eql(u8, tree_string, "Node (Node (Node (Tip 1 Tip) 3 Node (Tip 4 Tip)) 5 Node (Tip 7 Tip))"));
    }

    const leaked = gpa.detectLeaks();
    try std.testing.expectEqual(leaked, false);
}
