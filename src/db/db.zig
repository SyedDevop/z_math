const zqlite = @import("zqlite");
const std = @import("std");

const ZAppErrors = @import("../errors.zig").ZAppErrors;
const Allocator = std.mem.Allocator;

const HOME_ENV = "HOME";

pub fn getDbPath() ![:0]u8 {
    var buf: [1024]u8 = undefined;
    if (std.posix.getenv(HOME_ENV)) |home_env| {
        return std.fmt.bufPrintZ(&buf, "{s}/z_math", .{home_env});
    }
    std.debug.print("{s} env not set\n", .{HOME_ENV});
    std.debug.print("Z_Math only supports the POSIX-compliant system.\n", .{});
    std.process.exit(1);
}
const Tabels = enum {
    Expressions,
};

pub const DB = struct {
    const Self = @This();

    alloc: Allocator,

    conn: zqlite.Conn,
    path: [:0]u8,
    pub fn init(allocator: Allocator) !Self {
        const db_path = try getDbPath();
        const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
        var conn = try zqlite.open(db_path, flags);
        try create_table(allocator, &conn);
        return .{
            .conn = conn,
            .path = db_path,
            .alloc = allocator,
        };
    }
    pub fn deinit(self: *Self) void {
        self.conn.close();
    }
    fn create_table(alloc: Allocator, conn: *zqlite.Conn) !void {
        const quer = try std.fmt.allocPrintZ(alloc,
            \\CREATE TABLE IF NOT EXISTS {s} (
            \\Id            INT PRIMARY KEY     NOT NULL,
            \\input         TEXT NOT NULL,
            \\output        TEXT NOT NULL,
            \\execution_id  TEXT NOT NULL,
            \\created_at    TEXT DEFAULT CURRENT_TIMESTAMP);
        , .{@tagName(Tabels.Expressions)});
        defer alloc.free(quer);
        conn.exec(quer, .{}) catch {
            std.debug.print("{s}", .{quer});
            std.debug.print("{s}", .{conn.lastError()});
            std.process.exit(1);
        };
        const query = try std.fmt.allocPrintZ(alloc, "CREATE INDEX IF NOT EXISTS idx_execution_id ON {s} (execution_id);", .{@tagName(Tabels.Expressions)});
        defer alloc.free(query);
        try conn.execNoArgs(query);
    }
};
