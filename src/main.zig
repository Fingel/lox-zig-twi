const std = @import("std");

const maxFileSize: u32 = 1024 * 64;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const stdout = std.io.getStdOut().writer();
    const args = std.os.argv;

    if (args.len > 2) {
        try stdout.print("Usage: loz [script]", .{});
        std.process.exit(64);
    } else if (args.len == 2) {
        const path = std.mem.span(args[1]);
        try runFile(allocator, path);
    } else {
        try runPrompt(allocator);
    }
}

fn runFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile(path, .{});
    defer file.close();

    var r = file.reader();
    const msg = r.readAllAlloc(allocator, maxFileSize) catch |err| {
        if (err == error.StreamTooLong) {
            print("Error: file too large\n", .{});
            std.process.exit(64);
        }
        return err;
    };
    defer allocator.free(msg);

    print("msg: {s}\n", .{msg});
}

fn runPrompt(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    while (true) {
        try stdout.print("> ", .{});
        const input = stdin.readUntilDelimiterAlloc(allocator, '\n', maxFileSize) catch |err| {
            if (err == error.StreamTooLong) {
                print("Error: input too large\n", .{});
                std.process.exit(64);
            }
            return err;
        };
        defer allocator.free(input);

        if (std.mem.eql(u8, input, "exit")) {
            std.process.exit(0);
        } else {
            try stdout.print("You entered: {s}\n", .{input});
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
