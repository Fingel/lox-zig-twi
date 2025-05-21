const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;
const Literal = @import("token.zig").Literal;
const errorLine = @import("main.zig").errorLine;

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

    pub fn scanTokens(self: *Scanner) []Token {
        while (!self.isAtEnd()) : (self.start = self.current) {
            self.scanToken();
        }

        self.tokens.append(Token{
            .type = TokenType.EOF,
            .lexeme = "",
            .literal = null,
            .line = 0,
        }) catch |err| {
            std.debug.panic("UNRECOVERABLE - COULD NOT APPEND TOKEN {}", .{err});
        };

        return self.tokens.items;
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn scanToken(self: *Scanner) void {
        const c: u8 = self.advance();
        switch (c) {
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
            '!' => {
                if (self.match('=')) self.addToken(TokenType.BANG_EQUAL) else self.addToken(TokenType.BANG);
            },
            '=' => {
                if (self.match('=')) self.addToken(TokenType.EQUAL_EQUAL) else self.addToken(TokenType.EQUAL);
            },
            '<' => {
                if (self.match('=')) self.addToken(TokenType.LESS_EQUAL) else self.addToken(TokenType.LESS);
            },
            '>' => {
                if (self.match('=')) self.addToken(TokenType.GREATER_EQUAL) else self.addToken(TokenType.GREATER);
            },
            '/' => {
                if (self.match('/')) {
                    // Comments, read to newline
                    while (self.peek() != '\n' and !self.isAtEnd()) _ = self.advance();
                } else {
                    self.addToken(TokenType.SLASH);
                }
            },
            ' ' => {},
            '\r' => {},
            '\t' => {},
            '\n' => {
                self.line += 1;
            },
            '"' => {
                self.string();
            },
            else => {
                if (self.isDigit(c)) {
                    self.number();
                } else {
                    errorLine(self.line, "Unexpected character");
                }
            },
        }
    }

    fn number(self: *Scanner) void {
        while (self.isDigit(self.peek())) _ = self.advance();

        // Look for a fractional part.
        if (self.peek() == '.' and self.isDigit(self.peekNext())) {
            // Consume the .
            _ = self.advance();

            while (self.isDigit(self.peek())) _ = self.advance();
        }

        const value: f64 = std.fmt.parseFloat(f64, self.source[self.start..self.current]) catch {
            errorLine(self.line, "Could not parse float");
            return;
        };
        self.addLiteralToken(TokenType.NUMBER, Literal{ .Number = value });
    }

    fn string(self: *Scanner) void {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }
        if (self.isAtEnd()) {
            errorLine(self.line, "Unterminated string");
            return;
        }
        _ = self.advance();
        const value = self.source[self.start + 1 .. self.current - 1];

        self.addLiteralToken(TokenType.STRING, Literal{ .String = value });
    }

    fn match(self: *Scanner, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isDigit(self: *Scanner, c: u8) bool {
        _ = self;
        return c >= '0' and c <= '9';
    }

    fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn addToken(self: *Scanner, token_type: TokenType) void {
        self.addLiteralToken(token_type, null);
    }

    fn addLiteralToken(self: *Scanner, token_type: TokenType, literal: ?Literal) void {
        const lexeme = self.source[self.start..self.current];
        self.tokens.append(Token{
            .type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = self.line,
        }) catch |err| {
            std.debug.panic("UNRECOVERABLE - COULD NOT APPEND TOKEN {}", .{err});
        };
    }
};
const expect = @import("std").testing.expect;

test "test single token" {
    var scanner = Scanner.init(std.testing.allocator, "*");
    const result = scanner.scanTokens();
    try expect(result.len == 2);
    try expect(result[0].type == TokenType.STAR);
    try expect(result[1].type == TokenType.EOF);
    scanner.deinit();
}

test "test double token" {
    var scanner = Scanner.init(std.testing.allocator, "!=");
    const result = scanner.scanTokens();
    try expect(result.len == 2);
    try expect(result[0].type == TokenType.BANG_EQUAL);
    try expect(result[1].type == TokenType.EOF);
    scanner.deinit();
}

test "test comment token" {
    var scanner = Scanner.init(std.testing.allocator, "// This is a comment");
    const result = scanner.scanTokens();
    // There should be nothing, this program is just a comment.
    try expect(result.len == 1);
    try expect(result[0].type == TokenType.EOF);
    scanner.deinit();
}

test "test whitespace" {
    var scanner = Scanner.init(std.testing.allocator, "\r\n");
    const result = scanner.scanTokens();
    // There should be nothing, this program is just whitespace.
    try expect(result.len == 1);
    try expect(result[0].type == TokenType.EOF);
    scanner.deinit();
}

test "test strings" {
    var scanner = Scanner.init(std.testing.allocator, "\"hello world!\"");
    const result = scanner.scanTokens();
    try expect(result.len == 2);
    try expect(result[0].type == TokenType.STRING);
    const token = result[0].literal.?;
    try expect(std.mem.eql(u8, token.String, "hello world!"));
    try expect(result[1].type == TokenType.EOF);
    scanner.deinit();
}

test "test numbers" {
    var scanner = Scanner.init(std.testing.allocator, "420.69");
    const result = scanner.scanTokens();
    try expect(result.len == 2);
    try expect(result[0].type == TokenType.NUMBER);
    const token = result[0].literal.?;
    try expect(token.Number == 420.69);
    try expect(result[1].type == TokenType.EOF);
    scanner.deinit();
}
