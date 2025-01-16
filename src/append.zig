const std = @import("std");

const stdout = std.io.getStdOut().writer();
pub fn append(a: []const u8, b: []const u8, limiter: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator;
    const result = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ a, limiter, b });
    return result;
}
