const std = @import("std");

const Token = union(enum) {
    number: f64,
    plus: void,
    minus: void,
    multiply: void,
    divide: void,
};

fn tokenize(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(allocator);
    errdefer tokens.deinit();

    var index: usize = 0;
    var prev_token_is_operator_or_none = true;

    while (index < input.len) {
        const c = input[index];
        switch (c) {
            '0'...'9', '.' => {
                const start = index;
                while (index < input.len and (std.ascii.isDigit(input[index]) or input[index] == '.')) : (index += 1) {}
                const num_str = input[start..index];
                const num = std.fmt.parseFloat(f64, num_str) catch {
                    std.log.err("Invalid number: '{s}'", .{num_str});
                    return error.InvalidNumber;
                };
                try tokens.append(Token{ .number = num });
                prev_token_is_operator_or_none = false;
            },
            '+' => {
                try tokens.append(Token.plus);
                index += 1;
                prev_token_is_operator_or_none = true;
            },
            '-' => {
                if (prev_token_is_operator_or_none) {
                    // Handle unary minus
                    const start = index;
                    index += 1;
                    var has_digits = false;
                    while (index < input.len and (std.ascii.isDigit(input[index]) or input[index] == '.')) : (index += 1) {
                        has_digits = true;
                    }
                    if (!has_digits) {
                        std.log.err("Invalid unary minus", .{});
                        return error.InvalidNumber;
                    }
                    const num_str = input[start..index];
                    const num = std.fmt.parseFloat(f64, num_str) catch |err| {
                        std.log.err("Invalid number: '{s}'", .{num_str});
                        return err;
                    };
                    try tokens.append(Token{ .number = num });
                    prev_token_is_operator_or_none = false;
                } else {
                    // Binary minus
                    try tokens.append(Token.minus);
                    index += 1;
                    prev_token_is_operator_or_none = true;
                }
            },
            '*' => {
                try tokens.append(Token.multiply);
                index += 1;
                prev_token_is_operator_or_none = true;
            },
            '/' => {
                try tokens.append(Token.divide);
                index += 1;
                prev_token_is_operator_or_none = true;
            },
            ' ' => {
                // Skip whitespace
                index += 1;
            },
            else => {
                std.log.err("Invalid character: '{c}'", .{c});
                return error.InvalidCharacter;
            },
        }
    }

    return tokens;
}

fn getPrecedence(token: Token) u8 {
    return switch (token) {
        .multiply, .divide => 2,
        .plus, .minus => 1,
        else => 0,
    };
}

fn shuntingYard(allocator: std.mem.Allocator, tokens: []const Token) !std.ArrayList(Token) {
    var output = std.ArrayList(Token).init(allocator);
    errdefer output.deinit();
    var stack = std.ArrayList(Token).init(allocator);
    defer stack.deinit();

    for (tokens) |token| {
        switch (token) {
            .number => try output.append(token),
            .plus, .minus, .multiply, .divide => {
                const curr_prec = getPrecedence(token);
                while (stack.items.len > 0) {
                    const top_token = stack.items[stack.items.len - 1];
                    const top_prec = getPrecedence(top_token);
                    if (top_prec >= curr_prec) {
                        try output.append(stack.pop());
                    } else {
                        break;
                    }
                }
                try stack.append(token);
            },
        }
    }

    while (stack.popOrNull()) |op| {
        try output.append(op);
    }

    return output;
}

fn evaluatePostfix(allocator: std.mem.Allocator, tokens: []const Token) !f64 {
    var stack = std.ArrayList(f64).init(allocator);
    defer stack.deinit();

    for (tokens) |token| {
        switch (token) {
            .number => |val| {
                try stack.append(val);
            },
            else => {
                if (stack.items.len < 2) {
                    return error.InvalidExpression;
                }
                const b = stack.pop();
                const a = stack.pop();
                const result = switch (token) {
                    .plus => a + b,
                    .minus => a - b,
                    .multiply => a * b,
                    .divide => {
                        if (b == 0.0) {
                            return error.DivisionByZero;
                        }
                        return a / b;
                    },
                    else => unreachable,
                };
                try stack.append(result);
            },
        }
    }

    if (stack.items.len != 1) {
        return error.InvalidExpression;
    }

    return stack.items[0];
}

fn evaluateExpression(allocator: std.mem.Allocator, expr: []const u8) !f64 {
    var tokens = try tokenize(allocator, expr);
    defer tokens.deinit();

    var postfix = try shuntingYard(allocator, tokens.items);
    defer postfix.deinit();

    return try evaluatePostfix(allocator, postfix.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip executable name
    _ = args.next();

    const expr = args.next() orelse {
        std.debug.print("Usage: {any} <expression>\n", .{args.next()});
        return error.InvalidArgs;
    };

    const result = evaluateExpression(allocator, expr) catch |err| {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        return err;
    };
    std.debug.print("{d}\n", .{result});
}
