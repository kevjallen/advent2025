const std = @import("std");

const Range = struct {
    start: usize = 0,
    end: usize = 0,

    pub fn order(self: Range, other: Range) std.math.Order {
        if (self.start < other.start) {
            return .lt;
        } else if (self.start > other.start) {
            return .gt;
        } else if (self.end < other.end) {
            return .lt;
        } else if (self.end > other.end) {
            return .gt;
        }
        return .eq;
    }

    pub fn equals(self: Range, other: Range) bool {
        return self.order(other) == .eq;
    }

    pub fn lessThan(_: void, a: Range, b: Range) bool {
        return a.order(b) == .lt;
    }

    pub fn includes(self: Range, id: usize) bool {
        return id >= self.start and id <= self.end;
    }

    pub fn overlaps(self: Range, other: Range) bool {
        return self.end + 1 >= other.start and other.end + 1 >= self.start;
    }

    pub fn merge(self: Range, other: Range) Range {
        return Range{
            .start = @min(self.start, other.start),
            .end = @max(self.end, other.end),
        };
    }

    pub fn size(self: Range) !usize {
        if (self.start > self.end) return error.InvalidRange;
        return self.end - self.start + 1;
    }
};

pub fn solve(input: []const u8) !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    var iter = std.mem.tokenizeScalar(u8, input, '\n');

    var id_ranges: std.array_list.Managed(Range) = .init(allocator);
    defer id_ranges.deinit();

    // read ranges
    while (iter.next()) |range_str| {
        var split = std.mem.splitScalar(u8, range_str, '-');

        const start_str = split.next() orelse return error.InvalidInput;
        const end_str = split.next() orelse return error.InvalidInput;

        const range = Range{
            .start = try std.fmt.parseInt(usize, start_str, 10),
            .end = try std.fmt.parseInt(usize, end_str, 10),
        };

        try id_ranges.append(range);

        const peek = iter.peek() orelse "";
        if (std.mem.count(u8, peek, "-") == 0) {
            break;
        }
    }

    // read ids and count valid ones
    var id_count: usize = 0;
    while (iter.next()) |id_str| {
        const id = try std.fmt.parseInt(usize, id_str, 10);
        for (id_ranges.items) |range| {
            if (range.includes(id)) {
                id_count += 1;
                break;
            }
        }
    }

    var merged_id_ranges: std.array_list.Managed(Range) = .init(allocator);
    defer merged_id_ranges.deinit();

    std.mem.sort(Range, id_ranges.items, {}, Range.lessThan);

    // merge overlapping ranges
    for (id_ranges.items) |range| {
        if (merged_id_ranges.items.len == 0) {
            try merged_id_ranges.append(range);
            continue;
        }

        var last_merged = merged_id_ranges.items[merged_id_ranges.items.len - 1];
        if (last_merged.overlaps(range)) {
            const new_merged = last_merged.merge(range);
            merged_id_ranges.items[merged_id_ranges.items.len - 1] = new_merged;
        } else {
            try merged_id_ranges.append(range);
        }
    }

    // count total valid ids
    var valid_count: usize = 0;
    for (merged_id_ranges.items) |range| {
        valid_count += try range.size();
    }

    std.debug.print("Valid IDs in list (part 1): {d}\n", .{id_count});
    std.debug.print("Total valid IDs (part 2): {d}\n", .{valid_count});
}
