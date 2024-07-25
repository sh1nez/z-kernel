const builtin = @import("builtin");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const VgaColor = u8;
const VGA_COLOR_BLACK = 0;
const VGA_COLOR_BLUE = 1;
const VGA_COLOR_GREEN = 2;
const VGA_COLOR_CYAN = 3;
const VGA_COLOR_RED = 4;
const VGA_COLOR_MAGENTA = 5;
const VGA_COLOR_BROWN = 6;
const VGA_COLOR_LIGHT_GREY = 7;
const VGA_COLOR_DARK_GREY = 8;
const VGA_COLOR_LIGHT_BLUE = 9;
const VGA_COLOR_LIGHT_GREEN = 10;
const VGA_COLOR_LIGHT_CYAN = 11;
const VGA_COLOR_LIGHT_RED = 12;
const VGA_COLOR_LIGHT_MAGENTA = 13;
const VGA_COLOR_LIGHT_BROWN = 14;
const VGA_COLOR_WHITE = 15;

const VGA_WIDTH = 80;
const VGA_WEIGHT = 25;

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

export var multiboot align(4) linksection(".multiboot") = MultiBoot{ .magic = MAGIC, .flags = FLAGS, .checksum = -(MAGIC + FLAGS) };

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes[0..] }, kernel_main, .{});
}

fn kernel_main() void { // callconv(.Naked)
    tty.write("Hello from kernel world!");
    while (true) {}
}

const tty = struct {
    var row: usize = 0;
    var column: usize = 0;
    var color: u8 = VGA_COLOR_DARK_GREY | u8(VGA_COLOR_BLACK << 4); // fg | bg
    //
    const buffer: [*]volatile u16 = @ptrFromInt(0xB8000);

    inline fn char_to_vga(uc: u8) u16 {
        return uc | (u16(color) << 8);
    }

    fn putch(char: u8) void {
        buffer[VGA_WIDTH * row + column] = char_to_vga(char);

        column += 1;
        if (column == VGA_WEIGHT) {
            column = 0;
            row += 1;
        }
    }

    fn write(date: []const u8) void {
        for (&date) |*ch| {
            putch(ch.*);
        }
    }
};
