const token = @import("token.zig");
const std = @import("std");
const mem = std.mem;

pub const Expr = union(enum) {
    Binary: struct {
        left: *const Expr,
        operator: token.Token,
        right: *const Expr,
    },
    Literal: struct {
        value: token.Literal,
    },
    Unary: struct {
        operator: token.Token,
        right: *const Expr,
    },
    Grouping: struct {
        expression: *const Expr,
    },
};

pub fn print(allocator: std.mem.Allocator, expr: *const Expr) anyerror![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    errdefer list.deinit();

    try printToArray(&list, expr);
    return list.toOwnedSlice();
}

fn printToArray(list: *std.ArrayList(u8), expr: *const Expr) anyerror!void {
    switch (expr.*) {
        .Binary => |bin| {
            try parenthesize(list, bin.operator.lexeme, &[_]*const Expr{ bin.left, bin.right });
        },
        .Grouping => |grp| {
            try parenthesize(list, "group", &[_]*const Expr{grp.expression});
        },
        .Literal => |lit| {
            try std.fmt.format(list.writer(), "{s}", .{lit.value});
        },
        .Unary => |unary| {
            try parenthesize(list, unary.operator.lexeme, &[_]*const Expr{unary.right});
        },
    }
}

pub fn parenthesize(list: *std.ArrayList(u8), name: []const u8, expressions: []const *const Expr) !void {
    try std.fmt.format(list.writer(), "({s}", .{name});
    for (expressions) |expr| {
        try list.appendSlice(" ");
        try printToArray(list, expr);
    }
    try list.appendSlice(")");
}

test "Pretty print a Binary" {
    const allocator = std.testing.allocator;

    const expr = Expr{
        .Binary = .{
            .left = &Expr{
                .Unary = .{
                    .operator = token.Token{
                        .type = token.TokenType.MINUS,
                        .lexeme = "-",
                        .literal = null,
                        .line = 1,
                    },
                    .right = &Expr{
                        .Literal = .{
                            .value = token.Literal{ .Number = 123 },
                        },
                    },
                }, // unary
            }, // left
            .operator = token.Token{
                .lexeme = "*",
                .type = token.TokenType.STAR,
                .line = 1,
                .literal = null,
            }, // operator
            .right = &Expr{
                .Grouping = .{
                    .expression = &Expr{
                        .Literal = .{
                            .value = token.Literal{ .Number = 45.67 },
                        },
                    },
                }, // grouping
            }, //right
        },
    };
    const pprint = try print(allocator, &expr);
    defer allocator.free(pprint);
    std.debug.print("{s}\n", .{pprint});
    try std.testing.expectEqualStrings("(* (- 123) (group 45.67))", pprint);
}
