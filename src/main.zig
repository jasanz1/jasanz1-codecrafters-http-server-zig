const std = @import("std");
const net = std.net;
const request = @import("request.zig");
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
        _ = try std.Thread.spawn(.{}, handleRequest, .{connection});
    }
}

fn handleRequest(connection: net.Server.Connection) !void {
    defer connection.stream.close();
    try stdout.print("client connected!\n", .{});
    var trimBuffer: [1024]u8 = undefined;
    _ = try connection.stream.read(&trimBuffer);
    var buffer = std.mem.tokenizeSequence(u8, &trimBuffer, "\r\n\r\n");
    const requestLineAndHeaders = buffer.next().?;
    var curRequest = std.mem.tokenizeSequence(u8, requestLineAndHeaders, "\r\n");
    var requestLineToken = std.mem.tokenizeScalar(u8, curRequest.next().?, ' ');

    var activeRequest = ActiveRequest{
        .method = requestLineToken.next().?,
        .path = std.mem.tokenizeScalar(u8, requestLineToken.next().?, '/'),
        .version = requestLineToken.next().?,
        .headers = curRequest,
        .body = buffer.next().?, // request.next().?,
    };
    const response = determineResponse(&activeRequest);

    try stdout.print("response:\n{s}\n", .{try response});
    _ = try connection.stream.write(try response);
}

fn determineResponse(curRequest: *ActiveRequest) ![]const u8 {
    var path = curRequest.path;
    var requestHeaders = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    defer requestHeaders.deinit();
    while (curRequest.headers.peek() != null) {
        const header = curRequest.headers.next().?;
        var headerToken = std.mem.tokenizeSequence(u8, header, ": ");
        const key = headerToken.next().?;
        const value = headerToken.next().?;
        try requestHeaders.put(key, value);
    }
    const baseToken = path.next() orelse "";
    var basePathToken = std.mem.tokenizeScalar(u8, baseToken, '/');
    const nakedBasePath = basePathToken.next() orelse "";
    const basePath = try append("/", nakedBasePath, "");
    if (std.mem.eql(u8, curRequest.method, "GET")) {
        if (std.mem.eql(u8, basePath, "/")) {
            const response = responseCode.ok("", "");
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
        } else if (std.mem.eql(u8, basePath, "/files")) {
            if (responseBody.files(&path)) |body| {
                const header = responseHeaders.application(body);
                const response = responseCode.ok(header, body);
                return response;
            } else |err| {
                try stdout.print("error: {s}\n", .{@errorName(err)});
                const response = responseCode.notFound("", "");
                return response;
            }
        } else {
            const response = responseCode.notFound("", "");
            return response;
        }
    } else if (std.mem.eql(u8, curRequest.method, "POST")) {
        if (std.mem.eql(u8, basePath, "/files")) {
            const length = std.fmt.parseInt(u8, requestHeaders.get("Content-Length") orelse "", 10) catch 0;
            const body = curRequest.body[0..length];
            try request.postFiles(&path, body);
            const response = responseCode.created("", "");
            return response;
        }
    }
    const response = responseCode.notFound("", "");
    return response;
}
