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

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
    literal: ?*anyopaque,

    fn init(tType: TokenType, lexeme: []const u8, line: u32, literal: ?*anyopaque) Token {
        return Token{
            .type = tType,
            .lexeme = lexeme,
            .line = line,
            .literal = literal,
        };
    }

    pub fn format(self: Token, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} {s} {any}", .{ @tagName(self.type), self.lexeme, self.literal });
    }
};
