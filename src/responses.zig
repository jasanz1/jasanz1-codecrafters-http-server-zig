const std = @import("std");
const net = std.net;
const stdout = std.io.getStdOut().writer();
pub fn ok(connection: net.Server.Connection) !void {
    try stdout.print("sending OK!\n", .{});
    _ = try connection.stream.write("HTTP/1.1 200 OK\r\n\r\n");
}

pub fn notFound(connection: net.Server.Connection) !void {
    try stdout.print("sending Not Found!\n", .{});
    _ = try connection.stream.write("HTTP/1.1 404 Not Found\r\n\r\n");
}
