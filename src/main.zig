const std = @import("std");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <day> <input_file>\n", .{args[0]});
        return;
    }

    const day = try std.fmt.parseInt(u8, args[1], 10);

    const input_file = try std.fs.cwd().openFile(args[2], .{ .mode = .read_only });
    defer input_file.close();

    const input = try input_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(input);

    switch (day) {
        1 => try day1.solve(input),
        2 => try day2.solve(input),
        3 => try day3.solve(input),
        else => {
            std.debug.print("Day {} not implemented yet.\n", .{day});
        }
    }
}
