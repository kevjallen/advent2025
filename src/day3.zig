const std = @import("std");

fn calculateJoltage(bank: []const u8) !usize {
    var ones: u8 = 1;
    var tens: u8 = 1;

    for (bank) |ch| {
        const n = ch - '0';

        if (ones > tens) {
            tens = ones;
            ones = n;
        } else if (n > ones) {
            ones = n;
        }
    }
    return 10 * tens + ones;
}

fn calculateJoltageV2(bank: []const u8) !usize {
    var buf: [12]u8 = .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 };

    for (bank) |ch| {
        const n = ch - '0';

        var i: usize = buf.len - 1;
        while (i > 0) : (i -= 1) {
            if (buf[i] < buf[i - 1]) {
                // shift larger values to the right
                std.mem.copyBackwards(u8, buf[1..i + 1], buf[0..i]);
                buf[0] = 1;
                break;
            }
        }

        if (n > buf[0]) {
            buf[0] = n;
        }
    }

    var result: usize = 0;
    for (0..12) |i| {
        result = 10 * result + buf[buf.len - 1 - i];
    }
    return result;
}

pub fn solve(input: []const u8) !void {
    var counter: usize = 0;
    var counter_v2: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (iter.next()) |bank| {
        counter += try calculateJoltage(bank);
        counter_v2 += try calculateJoltageV2(bank);
    }

    std.debug.print("Total output joltage (part 1): {}\n", .{counter});
    std.debug.print("Total output joltage (part 2): {}\n", .{counter_v2});
}
