const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;

const maxFileSize: u32 = 1024 * 64;
const print = std.debug.print;

var hadError: bool = false;

pub fn errorLine(line: u32, message: []const u8) void {
    report(line, "", message);
}

pub fn report(line: u32, where: []const u8, message: []const u8) void {
    print("[line {d}] Error {s}: {s}\n", .{ line, where, message });
    hadError = true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const stdout = std.io.getStdOut().writer();
    var interpreter = Lox{ .allocator = allocator };

    const args = std.os.argv;
    if (args.len > 2) {
        try stdout.print("Usage: loz [script]", .{});
        std.process.exit(64);
    } else if (args.len == 2) {
        const path = std.mem.span(args[1]);
        try interpreter.runFile(path);
    } else {
        try interpreter.runPrompt();
    }
}

const Lox = struct {
    allocator: std.mem.Allocator,

    fn runFile(self: *Lox, path: []const u8) !void {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile(path, .{});
        defer file.close();

        var r = file.reader();
        const msg = r.readAllAlloc(self.allocator, maxFileSize) catch |err| {
            switch (err) {
                error.StreamTooLong => {
                    print("Error: file too large\n", .{});
                    std.process.exit(64);
                },
                else => return err,
            }
        };
        defer self.allocator.free(msg);

        try self.run(msg);

        // Indicate an error in the exit code
        if (hadError) std.process.exit(65);
    }

    fn runPrompt(self: *Lox) !void {
        const stdout = std.io.getStdOut().writer();
        const stdin = std.io.getStdIn().reader();

        while (true) {
            try stdout.print("> ", .{});
            const line = stdin.readUntilDelimiterAlloc(self.allocator, '\n', maxFileSize) catch |err| {
                switch (err) {
                    error.StreamTooLong => {
                        print("Error: input too large\n", .{});
                        std.process.exit(64);
                    },
                    error.EndOfStream => std.process.exit(0),
                    else => return err,
                }
            };
            defer self.allocator.free(line);

            try self.run(line);
            hadError = false;
        }
    }

    fn run(self: *Lox, source: []const u8) !void {
        var scanner = Scanner.init(self.allocator, source);
        defer scanner.deinit();
        const tokens = try scanner.scanTokens();
        print("Tokens: {s}\n", .{tokens});
    }
};

const expect = @import("std").testing.expect;

test "has tokens" {
    var lox = Lox{ .allocator = std.testing.allocator };
    try lox.run("[];");
}
