const std = @import("std");
const net = std.net;

pub fn ok(connection: net.Server.Connection) !void {
    try connection.stream.writeAll("HTTP/1.1 200 OK\r\n\r\n");
}

pub fn notFound(connection: net.Server.Connection) !void {
    try connection.stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n");
}
