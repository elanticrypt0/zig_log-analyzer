const std = @import("std");
const testing = std.testing;

fn createTestAllocator() testing.allocator {
    return testing.allocator;
}

fn createTempLogFile(allocator: std.mem.Allocator, content: []const u8) ![]const u8 {
    const temp_path = "temp_test.log";
    const file = try std.fs.cwd().createFile(temp_path, .{});
    defer file.close();

    try file.writeall(content);
    return try allocator.dupe(u8, temp_path);
}

test "detectar ERROR en línea de log" {
    const test_line = "2024-01-06 08:24:31 ERROR [Firewall] Potential port scan detected";
    const found = std.mem.indexOf(u8, test_line, "ERROR");
    try testing.expect(found != null);
}

test "contar líneas y errores del archivo" {
    const test_content =
        \\2024-01-06 08:23:15 INFO [AuthService] User login successful
        \\2024-01-06 08:24:31 ERROR [Firewall] Potential port scan detected
        \\2024-01-06 08:24:32 ERROR [IDS] Signature match: SQL injection attempt
    ;

    var line_count: usize = 0;
    var error_count: usize = 0;

    var fbs = std.io.fixedBufferStream(test_content);
    var reader = fbs.reader();
    var buf: [1024]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        line_count += 1;
        if (std.mem.indexOf(u8, line, "ERROR") != null) {
            error_count += 1;
        }
    }

    try testing.expectEqual(@as(usize, 3), line_count);
    try testing.expectEqual(@as(usize, 2), error_count);
}

test "manejo de archivo vacio" {
    const test_content = "";
    var fbs = std.io.fixedBufferStream(test_content);
    var reader = fbs.reader();
    var buf: [1024]u8 = undefined;
    var line_count: usize = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |_| {
        line_count += 1;
    }
}

test "archivo con líneas largas" {
    const long_line = "a" ** 8192;
    const test_content = try std.fmt.allocPrint(testing.allocator, "2024-01-06 08:24:31 ERROR [Test] {s}\n", .{long_line});
    defer testing.allocator.free(test_content);

    var fsb = std.io.fixedBufferStream(test_content);
    var reader = fsb.reader();
    var buf: [16384]u8 = undefined;

    if (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try testing.expect(std.mem.indexOf(u8, line, "ERROR") != null);
        try testing.expect(line.len > 8192);
    } else {
        try testing.expect(false);
    }
}

test "verificar formato de timestamp" {
    const test_line = "2024-01-06 08:24:31 ERROR [Test] Sample error";
    const timestamp = test_line[0..19];

    try testing.expectEqualStrings("2024-01-06 08:24:31", timestamp);
}
