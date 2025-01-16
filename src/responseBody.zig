const std = @import("std");
const append = @import("append.zig").append;
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
