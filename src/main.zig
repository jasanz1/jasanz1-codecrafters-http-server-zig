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
    headers: std.mem.TokenIterator(u8, .sequence),
    body: []const u8,
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

    while (true) {
        const connection = try listener.accept();
        defer connection.stream.close();

        try stdout.print("client connected!\n", .{});
        var trimBuffer: [1024]u8 = undefined;
        _ = try connection.stream.read(&trimBuffer);
        var buffer = std.mem.tokenizeSequence(u8, &trimBuffer, "\r\n\r\n");
        const requestLineAndHeaders = buffer.next().?;
        var request = std.mem.tokenizeSequence(u8, requestLineAndHeaders, "\r\n");
        var requestLineToken = std.mem.tokenizeScalar(u8, request.next().?, ' ');

        var activeRequest = ActiveRequest{
            .method = requestLineToken.next().?,
            .path = std.mem.tokenizeScalar(u8, requestLineToken.next().?, '/'),
            .version = requestLineToken.next().?,
            .headers = request,
            .body = "", // request.next().?,
        };
        const response = determineResponse(&activeRequest);

        try stdout.print("response:\n{s}\n", .{try response});
        _ = try connection.stream.write(try response);
    }
}
fn determineResponse(request: *ActiveRequest) ![]const u8 {
    var path = request.path;
    var requestHeaders = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    defer requestHeaders.deinit();
    while (request.headers.peek() != null) {
        const header = request.headers.next().?;
        var headerToken = std.mem.tokenizeSequence(u8, header, ": ");
        const key = headerToken.next().?;
        const value = headerToken.next().?;
        try requestHeaders.put(key, value);
    }
    const baseToken = path.next() orelse "";
    var basePathToken = std.mem.tokenizeScalar(u8, baseToken, '/');
    const nakedBasePath = basePathToken.next() orelse "";
    const basePath = try append("/", nakedBasePath, "");
    if (std.mem.eql(u8, basePath, "/")) {
        const body = responseBody.empty(&path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.ok(header, body);
        return response;
    } else if (std.mem.eql(u8, basePath, "/echo")) {
        const body = responseBody.echo(&path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.ok(header, body);
        return response;
    } else if (std.mem.eql(u8, basePath, "/user-agent")) {
        const userAgent = requestHeaders.get("User-Agent") orelse "";
        const header = responseHeaders.textPlain(userAgent);
        const response = responseCode.ok(header, userAgent);
        return response;
    } else {
        const body = responseBody.empty(&path);
        const header = responseHeaders.textPlain(body);
        const response = responseCode.notFound(header, body);

        return response;
    }
}
