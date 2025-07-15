const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;

const Self = @This();

version: std.SemanticVersion = .{ .major = 0, .minor = 6, .patch = 0 },
git_hash: []const u8,
git_hash_short: []const u8,
compiled_date: []const u8,

pub fn init(b: *std.Build) !Self {
    var code: u8 = 0;
    const short_hash = short_hash: {
        const output = b.runAllowFail(
            &[_][]const u8{ "git", "-C", b.build_root.path orelse ".", "log", "--pretty=format:%h", "-n", "1" },
            &code,
            .Ignore,
        ) catch |err| switch (err) {
            error.FileNotFound => return error.GitNotFound,
            else => return err,
        };

        break :short_hash std.mem.trimRight(u8, output, "\r\n ");
    };

    const hash = hash: {
        const output = b.runAllowFail(
            &[_][]const u8{ "git", "rev-parse", "HEAD" },
            &code,
            .Ignore,
        ) catch |err| switch (err) {
            error.FileNotFound => return error.GitNotFound,
            else => return err,
        };
        break :hash std.mem.trimRight(u8, output, "\r\n");
    };
    const date = brk_date: {
        const date_cmd: []const []const u8 = switch (builtin.os.tag) {
            .linux => &[_][]const u8{ "date", "+%d/%m/%Y %r" },
            .windows => &[_][]const u8{ "powershell", "Get-Date -Format 'yyyy-MM-dd hh:mm:ss tt'" },
            else => return error.UnsupportedOSForDate,
        };
        const output = b.runAllowFail(
            date_cmd,
            &code,
            .Ignore,
        ) catch |err| switch (err) {
            error.FileNotFound => return error.DateNotFound,
            else => return err,
        };
        break :brk_date std.mem.trimRight(u8, output, "\r\n");
    };
    return .{
        .git_hash = hash,
        .git_hash_short = short_hash,
        .compiled_date = date,
    };
}

pub fn addLibs(self: *const Self, exe: *std.Build.Step.Compile, b: *std.Build) void {
    _ = self;

    exe.addIncludePath(b.path("lib"));
    // Add sqlite3;
    exe.addCSourceFile(.{ .file = b.path("lib/sqlite3.c"), .flags = &.{
        "-DSQLITE_DQS=0",
        "-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
        "-DSQLITE_USE_ALLOCA=1",
        "-DSQLITE_THREADSAFE=1",
        "-DSQLITE_TEMP_STORE=3",
        "-DSQLITE_ENABLE_API_ARMOR=1",
        "-DSQLITE_ENABLE_UNLOCK_NOTIFY",
        "-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1",
        "-DSQLITE_DEFAULT_FILE_PERMISSIONS=0600",
        "-DSQLITE_OMIT_DECLTYPE=1",
        "-DSQLITE_OMIT_DEPRECATED=1",
        "-DSQLITE_OMIT_LOAD_EXTENSION=1",
        "-DSQLITE_OMIT_PROGRESS_CALLBACK=1",
        "-DSQLITE_OMIT_SHARED_CACHE",
        "-DSQLITE_OMIT_TRACE=1",
        "-DSQLITE_OMIT_UTF16=1",
        "-DHAVE_USLEEP=0",
    } });
}

pub fn addOptions(self: *const Self, step: *std.Build.Step.Options) !void {
    var buf: [1024]u8 = undefined;

    step.addOption([]const u8, "name", "Z Math");
    step.addOption([]const u8, "git_hash", self.git_hash);
    step.addOption([]const u8, "git_hash_short", self.git_hash_short);
    step.addOption([]const u8, "compiled_date", self.compiled_date);
    step.addOption(std.SemanticVersion, "version", self.version);
    step.addOption([:0]const u8, "version_string", try std.fmt.bufPrintZ(
        &buf,
        "{}",
        .{self.version},
    ));
}

// pub fn run(self: Version, alloc: Allocator) !u8 {
//     _ = alloc;
//     _ = self;
//     app_version.parse("");
// }
