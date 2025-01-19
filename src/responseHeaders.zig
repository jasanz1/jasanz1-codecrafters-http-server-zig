const std = @import("std");
const append = @import("append.zig").append;
const stdout = std.io.getStdOut().writer();

pub fn textPlain(body: []const u8) []const u8 {
    const n = body.len;
    const allocator = std.heap.page_allocator;
    const headers = std.fmt.allocPrint(allocator, "Content-Type: text/plain\r\nContent-Length: {}\r\n", .{n}) catch "";

    return headers;
}

pub fn application(body: []const u8) []const u8 {
    const n = body.len;
    const allocator = std.heap.page_allocator;
    const headers = std.fmt.allocPrint(allocator, "Content-Type: application/octet-stream\r\nContent-Length: {}\r\n", .{n}) catch "";

    return headers;
}
