const std = @import("std");

// checks if input is made of two identical substrings
fn validateId(input: []const u8) bool {
    if (input.len % 2 != 0) {
        return true;
    }
    const half_len = input.len / 2;
    const left = input[0..half_len];
    const right = input[half_len..];

    return !std.mem.eql(u8, left, right);
}

// checks if input is made of multiple identical substrings
fn validateIdV2(input: []const u8) bool {
    if (input.len < 2) {
        return true;
    }

    const max_substr_len = input.len / 2;

    for (1..max_substr_len + 1) |substr_len| {
        if (input.len % substr_len != 0) {
            continue;
        }

        const pattern = input[0..substr_len];
        const substr_count = input.len / substr_len;

        var all_match = true;
        for (1..substr_count) |n| {
            const index = n * substr_len;
            const substr = input[index..index + substr_len];

            if (!std.mem.eql(u8, substr, pattern)) {
                all_match = false;
                break;
            }
        }
        if (all_match) {
            return false;
        }
    }
    return true;
}

fn strip(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;

    while (start < end and std.ascii.isWhitespace(s[start])) {
        start += 1;
    }
    while (end > start and std.ascii.isWhitespace(s[end - 1])) {
        end -= 1;
    }
    return s[start..end];
}

pub fn solve(input: []const u8) !void {
    var iter = std.mem.tokenizeScalar(u8, input, ',');
    var counter: usize = 0;
    var counter_v2: usize = 0;

    while (iter.next()) |id_range| {
        var split = std.mem.splitScalar(u8, id_range, '-');

        const start_id_str = split.next() orelse return error.InvalidInput;
        const end_id_str = split.next() orelse return error.InvalidInput;

        const start_id = try std.fmt.parseInt(usize, strip(start_id_str), 10);
        const end_id = try std.fmt.parseInt(usize, strip(end_id_str), 10);

        for (start_id..end_id) |id| {
            var buffer: [20]u8 = undefined;
            const id_str = try std.fmt.bufPrint(&buffer, "{}", .{id});

            if (validateId(id_str) == false) {
                counter += id;
            }
            if (validateIdV2(id_str) == false) {
                counter_v2 += id;
            }
        }
    }
    std.debug.print("Sum of invalid IDs (part 1): {}\n", .{counter});
    std.debug.print("Sum of invalid IDs (part 2): {}\n", .{counter_v2});
}
