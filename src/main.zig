const std = @import("std");
const net = std.net;
const response = @import("responses.zig");

const ActiveRequest = struct {
    method: []const u8,
    path: []const u8,
    version: []const u8,
};
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var activeRequest = ActiveRequest{
        .method = "",
        .path = "",
        .version = "",
    };
    // You can use print statements as follows for debugging, they'll be visible when running tests.
    try stdout.print("Logs from your program will appear here!\n", .{});

    // Uncomment this block to pass the first stage
    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    const connection = try listener.accept();
    defer connection.stream.close();
    try stdout.print("client connected!\n", .{});
    var buffer: [1024]u8 = undefined;
    _ = try connection.stream.read(&buffer);
    var request = std.mem.tokenizeSequence(u8, &buffer, "\r\n");
    var requestLineToken = std.mem.tokenizeScalar(u8, request.next().?, ' ');
    activeRequest.method = requestLineToken.next().?;
    activeRequest.path = requestLineToken.next().?;
    activeRequest.version = requestLineToken.next().?;

    if (std.mem.eql(u8, activeRequest.path, "/")) {
        try response.ok(connection);
    } else {
        try response.notFound(connection);
    }

    inline for (std.meta.fields(@TypeOf(activeRequest))) |f| {
        std.log.debug(f.name ++ " {s}", .{@as(f.type, @field(activeRequest, f.name))});
    }
}
