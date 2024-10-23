const zqlite = @import("zqlite");
const std = @import("std");

const ZAppErrors = @import("../errors.zig").ZAppErrors;
const Allocator = std.mem.Allocator;
const sql = @import("./sql_query.zig");
const Expr = @import("./expr.zig").Expr;

const HOME_ENV = "HOME";

pub fn getDbPath(alloc: Allocator) ![:0]u8 {
    if (std.posix.getenv(HOME_ENV)) |home_env| {
        return try std.fmt.allocPrintZ(alloc, "{s}/z_math", .{home_env});
    }
    std.debug.print("{s} env not set\n", .{HOME_ENV});
    std.debug.print("Z_Math only supports the POSIX-compliant system.\n", .{});
    std.process.exit(1);
}
pub const DB = struct {
    const Self = @This();

    alloc: Allocator,

    conn: zqlite.Conn,
    path: [:0]u8,
    pub fn init(allocator: Allocator) !Self {
        const db_path = try getDbPath(allocator);
        const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
        var conn = try zqlite.open(db_path, flags);
        try createTable(&conn);

        return .{
            .conn = conn,
            .path = db_path,
            .alloc = allocator,
        };
    }
    pub fn deinit(self: *Self) void {
        self.conn.close();
        self.alloc.free(self.path);
    }

    pub fn getAllEzprs(self: *Self, limit: u8) ![]Expr {
        var result = std.ArrayList(Expr).init(self.alloc);
        var rows = try self.conn.rows(sql.all_exper_query, .{limit});
        defer rows.deinit();
        while (rows.next()) |row| {
            const v = Expr{
                .id = row.int(0),
                .input = try self.alloc.dupe(u8, row.text(1)),
                .output = try self.alloc.dupe(u8, row.text(2)),
                .execution_id = try self.alloc.dupe(u8, row.text(3)),
                .created_at = try self.alloc.dupe(u8, row.text(4)),
            };
            try result.append(v);
        }
        return try result.toOwnedSlice();
    }

    fn createTable(conn: *zqlite.Conn) !void {
        conn.execNoArgs(sql.create_expression_table_query) catch {
            std.debug.print("{s}", .{sql.create_expression_table_query});
            std.debug.print("{s}", .{conn.lastError()});
            std.process.exit(1);
        };
        try conn.execNoArgs(sql.index_expression_query);
        // conn.exec("INSERT INTO Expressions (input,output,execution_id) VALUES (?1,?2,?3);", .{ "132*465", "123456", "79asd798" }) catch {
        //     std.debug.print("{s}\n", .{conn.lastError()});
        //     std.process.exit(1);
        // };
    }
};
