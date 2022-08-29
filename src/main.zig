const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const ascii = std.ascii;
const process = std.process;
const expect = std.testing.expect;

pub fn main() !void {
    var args_iterator = process.args();
    defer args_iterator.deinit();
    // we should skip the executable path
    // if true the next argument will be the pattern otherwise
    // there is no next argument so we should terminate
    if (!args_iterator.skip()) {
        return;
    }

    var pattern: []const u8 = undefined;
    var pattern_lps: []u32 = undefined;

    if (args_iterator.next()) |cli_pattern| {
        pattern = cli_pattern;
        pattern_lps = compute_lps(pattern);
    } else {
        return;
    }

    const max_size: usize = 1024;
    var fixed_buffer: [max_size]u8 = undefined;

    var fixed_size_alloc = heap.FixedBufferAllocator.init(&fixed_buffer);
    const allocator = fixed_size_alloc.allocator();

    const file = try fs.openFileAbsolute("/Users/eclesiojunior/proj/zig-grep/examples/file.txt", fs.File.OpenFlags{
        .mode = fs.File.OpenMode.read_only,
    });
    defer file.close();

    var file_metadata = try file.metadata();
    var file_size = file_metadata.size();

    var offset: usize = 0;
    var results: [][]u8 = undefined;

    while (true) {
        const amount_to_read = file_size - offset;

        var buf: []u8 = undefined;
        if (amount_to_read >= max_size) {
            buf = try allocator.alloc(u8, max_size);
        } else {
            buf = try allocator.alloc(u8, amount_to_read);
        }

        var bytes_read = try file.pread(buf, offset);
        if (bytes_read == 0) {
            allocator.free(buf);
            break;
        }

        if ((bytes_read + offset) < file_size and !ascii.isSpace(buf[buf.len - 1])) {
            while (!ascii.isSpace(buf[bytes_read - 1])) {
                bytes_read -= 1;
            }

            buf = try allocator.realloc(buf, bytes_read);
        }

        offset += bytes_read;

        try grep(buf, &results, "sit");

        allocator.free(buf);
    }
}

fn compute_lps(pattern: []const u8, lps_table: []usize) void {
    lps_table[0] = 0;

    // lets start from index 1 as index 0
    // of LPS slice already contains a value
    var i: usize = 1;

    // lenght of previous longest proper
    // prefix that is also a suffix
    var longest_lps: usize = 0;

    while (i < pattern.len) {
        if (pattern[longest_lps] == pattern[i]) {
            longest_lps += 1;
            lps_table[i] = longest_lps;
            i += 1;
        } else {
            if (longest_lps > 0) {
                longest_lps = lps_table[longest_lps - 1];
            } else {
                lps_table[i] = 0;
                i += 1;
            }
        }
    }
}

fn grep(buf: []u8, _: *const [][]u8, _: []const u8) !void {
    std.debug.print("{s} {d}\n", .{ buf, buf.len });
}

// TODO: test case sensitivity
test "compute LPS" {
    const Test = struct {
        pattern: []const u8,
        expected: []const usize,
    };

    const tests = [_]Test{
        .{
            .pattern = "ABABD",
            .expected = &.{ 0, 0, 1, 2, 0 },
        },

        .{
            .pattern = "AADAFG",
            .expected = &.{ 0, 1, 0, 1, 0, 0 },
        },

        .{
            .pattern = "abc",
            .expected = &.{ 0, 0, 0 },
        },
    };

    for (tests) |t| {
        var lps_table: []usize = undefined;
        lps_table = try std.testing.allocator.alloc(usize, t.pattern.len);
        compute_lps(t.pattern, lps_table);

        try expect(std.mem.eql(usize, lps_table, t.expected));
        std.testing.allocator.free(lps_table);
    }
}