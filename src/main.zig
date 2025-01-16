const std = @import("std");
const net = std.net;
const responseCode = @import("responsesCode.zig");
const responseHeaders = @import("responseHeaders.zig");
const responseBody = @import("responseBody.zig");
const append = @import("append.zig").append;
const stdout = std.io.getStdOut().writer();

const ActiveRequest = struct {
    method: []const u8,
    path: std.mem.TokenIterator(u8, .scalar),
    version: []const u8,
};
const ResponseComponents = struct {
    code: fn ([]const u8) []const u8,
    body: fn (std.mem.TokenIterator(u8, .scalar)) []const u8,
};

pub fn main() !void {
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

    var activeRequest = ActiveRequest{
        .method = requestLineToken.next().?,
        .path = std.mem.tokenizeScalar(u8, requestLineToken.next().?, '/'),
        .version = requestLineToken.next().?,
    };

    const response = determineResponse(&activeRequest.path);

    try stdout.print("response:\n {s}\n", .{try response});
    _ = try connection.stream.write(try response);
}

fn determineResponse(path: *std.mem.TokenIterator(u8, .scalar)) ![]const u8 {
    const baseToken = path.next() orelse "";
    var basePathToken = std.mem.tokenizeScalar(u8, baseToken, '/');
    const nakedBasePath = basePathToken.next() orelse "";
    const basePath = try append("/", nakedBasePath, "");
    if (std.mem.eql(u8, basePath, "/")) {
        const body = responseBody.empty(path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.ok(header, body);
        return response;
    } else if (std.mem.eql(u8, basePath, "/echo")) {
        const body = responseBody.echo(path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.ok(header, body);
        return response;
    } else {
        const body = responseBody.empty(path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.notFound(header, body);

        return response;
    }
}
