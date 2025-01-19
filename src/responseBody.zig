const std = @import("std");
const stdout = std.io.getStdOut().writer();
const append = @import("append.zig").append;
const fs = std.fs;
pub fn empty(_: *std.mem.TokenIterator(u8, .scalar)) []const u8 {
    return "";
}

pub fn echo(path: *std.mem.TokenIterator(u8, .scalar)) []const u8 {
    var response = path.next().?;
    while (path.next()) |token| {
        response = append(response, token, "/") catch "";
    }

    return response;
}

pub fn files(path: *std.mem.TokenIterator(u8, .scalar)) error{FileNotFound}![]const u8 {
    const filePath = path.next().?;
    var basePath: ?[]const u8 = null;
    var args = std.process.args();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--directory")) {
            basePath = args.next().?;
        }
    }
    const fullPath = append(basePath.?, filePath, "") catch "";
    var file = fs.cwd().openFile(fullPath, .{}) catch return error.FileNotFound;
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buffer: [1024]u8 = undefined;
    var response: []const u8 = "";
    while (in_stream.readUntilDelimiterOrEof(&buffer, '\n') catch "") |line| {
        response = append(response, line, "\n") catch "";
    }

    return response;
}
