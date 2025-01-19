const std = @import("std");
const net = std.net;
const append = @import("append.zig").append;
const stdout = std.io.getStdOut().writer();
pub fn ok(header: []const u8, body: []const u8) ![]const u8 {
    try stdout.print("sending OK!\n", .{});
    var response = try append("HTTP/1.1 200 OK\r\n", header, "");
    response = try append(response, "\r\n", "");
    response = try append(response, body, "");
    return response;
}

pub fn created(header: []const u8, body: []const u8) ![]const u8 {
    try stdout.print("sending Created!\n", .{});
    var response = try append("HTTP/1.1 201 Created\r\n", header, "");
    response = try append(response, "\r\n", "");
    response = try append(response, body, "");
    return response;
}

pub fn notFound(header: []const u8, body: []const u8) ![]const u8 {
    try stdout.print("sending Not Found!\n", .{});
    var response = try append("HTTP/1.1 404 Not Found\r\n", header, "");
    response = try append(response, "\r\n", "");
    response = try append(response, body, "");
    return response;
}
