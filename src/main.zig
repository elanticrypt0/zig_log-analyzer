const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try std.io.getStdOut().writer().print("Usage: {s} <logfile>\n", .{args[0]});
        return error.InvalidArguments;
    }

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var line_count: usize = 0;
    var error_count: usize = 0;

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        line_count += 1;

        if (std.mem.indexOf(u8, line, "ERROR") != null) {
            error_count += 1;
            try printLogEntry(line);
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\nSummary:\n", .{});
    try stdout.print("Total lines: {d}\n", .{line_count});
    try stdout.print("Error count: {d}\n", .{error_count});
}

fn printLogEntry(line: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{line});
}
