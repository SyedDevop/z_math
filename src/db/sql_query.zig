const std = @import("std");

var buf: [1024]u8 = undefined;

pub const Tabels = enum { Expressions };
pub const EXPR_TABLE: []const u8 = @tagName(Tabels.Expressions);

pub const create_expression_table_query =
    \\CREATE TABLE IF NOT EXISTS Expressions (
    \\id            INTEGER PRIMARY KEY,
    \\input         TEXT NOT NULL,
    \\output        TEXT NOT NULL,
    \\execution_id  TEXT NOT NULL,
    \\created_at    TEXT DEFAULT CURRENT_TIMESTAMP);
;

pub const index_expression_query = "CREATE INDEX IF NOT EXISTS idx_execution_id ON Expressions (execution_id);";

pub const all_exper_query = "SELECT * FROM (SELECT * FROM Expressions ORDER BY id DESC LIMIT ?1 ) ORDER BY id;";
