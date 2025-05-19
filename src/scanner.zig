const std = @import("std");
const Token = @import("token.zig").Token;
const tokens = @import("token.zig");

pub const Scanner = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Scanner {
        return Scanner{
            .source = source,
            .tokens = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.tokens.deinit();
    }

    pub fn scanTokens(self: *Scanner) ![]Token {
        try self.tokens.append(Token{
            .type = tokens.TokenType.EOF,
            .lexeme = "",
            .literal = null,
            .line = 0,
        });

        try self.tokens.append(Token{
            .type = tokens.TokenType.EOF,
            .lexeme = "",
            .literal = null,
            .line = 0,
        });
        return self.tokens.items;
    }
};
