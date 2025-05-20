const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const Scanner = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    start: usize = 0,
    current: usize = 0,
    line: u32 = 1,

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
        while (!self.isAtEnd()) : (self.start = self.current) {
            try self.scanToken();
        }

        try self.tokens.append(Token{
            .type = TokenType.EOF,
            .lexeme = "",
            .literal = null,
            .line = 0,
        });

        return self.tokens.items;
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn scanToken(self: *Scanner) !void {
        const c: u8 = self.advance();
        try switch (c) {
            '(' => self.addToken(TokenType.LEFT_PAREN),
            ')' => self.addToken(TokenType.RIGHT_PAREN),
            '{' => self.addToken(TokenType.LEFT_BRACE),
            '}' => self.addToken(TokenType.RIGHT_BRACE),
            ',' => self.addToken(TokenType.COMMA),
            '.' => self.addToken(TokenType.DOT),
            '-' => self.addToken(TokenType.MINUS),
            '+' => self.addToken(TokenType.PLUS),
            ';' => self.addToken(TokenType.SEMICOLON),
            '*' => self.addToken(TokenType.STAR),
            else => {},
        };
    }

    fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn addToken(self: *Scanner, token_type: TokenType) !void {
        try self.addLiteralToken(token_type, null);
    }

    fn addLiteralToken(self: *Scanner, token_type: TokenType, literal: ?*anyopaque) !void {
        const lexeme = self.source[self.start..self.current];
        try self.tokens.append(Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = self.line,
        });
    }
};
