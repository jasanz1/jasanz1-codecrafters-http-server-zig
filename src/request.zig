const std = @import("std");
const fs = std.fs;
const append = @import("append.zig").append;

pub fn postFiles(path: *std.mem.TokenIterator(u8, .scalar), body: []const u8) !void {
    std.debug.print("POST files with body: {s}\n", .{body});
    const filePath = path.next().?;
    var basePath: ?[]const u8 = null;
    var args = std.process.args();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--directory")) {
            basePath = args.next().?;
        }
    }
    const fullPath = append(basePath.?, filePath, "") catch "";
    var file = fs.createFileAbsolute(fullPath, .{}) catch return error.openError;
    try file.writeAll(body);
    defer file.close();
}
