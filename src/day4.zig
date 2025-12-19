const std = @import("std");

const RollExtractor = struct {
    count: usize = 0,

    top: []u8 = &[_]u8{},
    mid: []u8 = &[_]u8{},
    bot: []u8 = &[_]u8{},

    bot_count: usize = 0,
    extract_buf: []u8 = undefined,
    allocator: std.mem.Allocator = undefined,

    pub fn init(allocator: std.mem.Allocator, row_len: usize) !RollExtractor {
        return RollExtractor{
            .allocator = allocator,
            .extract_buf = try allocator.alloc(u8, row_len),
        };
    }

    pub fn deinit(self: *RollExtractor) void {
        if (self.top.len > 0) {
            self.allocator.free(self.top);
        }
        if (self.mid.len > 0) {
            self.allocator.free(self.mid);
        }
        if (self.bot.len > 0) {
            self.allocator.free(self.bot);
        }
        self.allocator.free(self.extract_buf);
    }

    pub fn addRow(self: *RollExtractor, row: []const u8) ![]const u8 {
        var copy: []u8 = undefined;
        if (row.len > 0) {
            copy = try self.allocator.alloc(u8, row.len);
            @memcpy(copy, row);
        } else {
            copy = &[_]u8{};
        }

        if (self.top.len > 0) {
            self.allocator.free(self.top);
        }

        self.top = self.mid;
        self.mid = self.bot;
        self.bot = copy;

        self.count -= self.bot_count;
        self.bot_count = 0;

        var idx: usize = 0;
        const row_len: usize = @max(self.mid.len, self.bot.len);
        while (idx < row_len) : (idx += 1) {
            var start: usize = idx;
            var end: usize = idx + 2;

            if (idx > 0) start -= 1;
            if (idx == row_len - 1) end -= 1;

            if (idx < self.mid.len) {
                self.extract_buf[idx] = self.mid[idx];
            }

            if (self.mid.len > 0 and self.mid[idx] == '@') {
                var mid_adjacent: usize = 0;

                if (self.top.len > 0) {
                    mid_adjacent += std.mem.count(u8, self.top[start..end], "@");
                }
                if (self.bot.len > 0) {
                    mid_adjacent += std.mem.count(u8, self.bot[start..end], "@");
                }
                mid_adjacent += std.mem.count(u8, self.mid[start..end], "@") - 1;

                if (mid_adjacent < 4) {
                    self.extract_buf[idx] = 'x';
                    self.count += 1;
                }
            }

            if (self.bot.len > 0 and self.bot[idx] == '@') {
                var bot_adjacent: usize = 0;

                if (self.mid.len > 0) {
                    bot_adjacent += std.mem.count(u8, self.mid[start..end], "@");
                }
                bot_adjacent += std.mem.count(u8, self.bot[start..end], "@") - 1;

                if (bot_adjacent < 4) {
                    self.bot_count += 1;
                }
            }
        }
        self.count += self.bot_count;
        return self.extract_buf[0..self.mid.len];
    }
};

pub fn solve(input: []const u8) !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    const allocator = arena_allocator.allocator();

    const row_len = std.mem.indexOf(u8, input, "\n") orelse input.len;

    var extractors: [256]RollExtractor = undefined;
    for (&extractors) |*e| {
        e.* = try RollExtractor.init(allocator, row_len);
    }
    defer for (&extractors) |*e| {
        e.deinit();
    };

    var iter = std.mem.tokenizeScalar(u8, input, '\n');

    // load input into extractor pipeline
    while (iter.next()) |line| {
        var result = try extractors[0].addRow(line);

        var extractor_idx: usize = 1;
        while (result.len > 0 and extractor_idx < extractors.len) {
            result = try extractors[extractor_idx].addRow(result);
            extractor_idx += 1;
        }
    }

    var roll_count: usize = 0;

    // flush remaining rows through the pipeline
    var idx: usize = 0;
    while (idx < extractors.len) : (idx += 1) {
        var result = try extractors[idx].addRow(&[_]u8{});

        if (extractors[idx].count == 0) break;

        roll_count += extractors[idx].count;

        var propagate_idx: usize = idx + 1;
        while (result.len > 0 and propagate_idx < extractors.len) {
            result = try extractors[propagate_idx].addRow(result);
            propagate_idx += 1;
        }
    }

    std.debug.print("Total rolls: {}\n", .{roll_count});
}
