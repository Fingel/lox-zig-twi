const std = @import("std");

pub const TokenType = enum {
    // zig fmt: off

    // Single-character tokens
    LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE, COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

    // One or two character tokens
    BANG, BANG_EQUAL, EQUAL, EQUAL_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL,

    // Literals
    IDENTIFIER, STRING, NUMBER,

    // Keywords
    AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR, PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

    EOF,
    // zig fmt: on
};

pub const Literal = union(enum) {
    String: []const u8,
    Bool: bool,
    Number: f64,

    pub fn format(self: Literal, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            .String => |str| try writer.print("{s}", .{str}),
            .Bool => |b| try writer.print("{s}", .{if (b) "true" else "false"}),
            .Number => |num| try writer.print("{d}", .{num}),
        }
    }
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
    literal: ?Literal,

    pub fn format(self: Token, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s}:{s}:{?}", .{ @tagName(self.type), self.lexeme, self.literal });
    }
};
