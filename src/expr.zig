const token = @import("token.zig");
const std = @import("std");
const mem = std.mem;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

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
    Grouping: struct { expression: *const Expr },
};

pub fn print(expr: *const Expr) anyerror![]const u8 {
    switch (expr.*) {
        .Binary => |bin| {
            return try parenthesize(bin.operator.lexeme, &[_]*const Expr{ bin.left, bin.right });
        },
        .Grouping => |grp| {
            return try parenthesize("group", &[_]*const Expr{grp.expression});
        },
        .Literal => |lit| {
            return try std.fmt.allocPrint(allocator, "{s}", .{lit.value});
        },
        .Unary => |unary| {
            return try parenthesize(unary.operator.lexeme, &[_]*const Expr{unary.right});
        },
    }
}

pub fn parenthesize(name: []const u8, expressions: []const *const Expr) ![]const u8 {
    var result = try std.fmt.allocPrint(allocator, "({s}", .{name});
    for (expressions) |expr| {
        result = try std.fmt.allocPrint(allocator, "{s} {s}", .{ result, try print(expr) });
    }
    result = try std.fmt.allocPrint(allocator, "{s})", .{result});

    return result;
}

test "Pretty print a Binary" {
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
    std.debug.print("{s}\n", .{try print(&expr)});
    try std.testing.expectEqualStrings("(* (- 123) (group 45.67))", try print(&expr));
}
