const std = @import("std");
const time = std.time;

const kernel_name = "2happyOS";

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .x86, .os_tag = .freestanding, .abi = .none });

    const kernel = b.addExecutable(.{ .name = kernel_name, .target = target, .root_source_file = b.path("src/main.zig") });

    kernel.setLinkerScriptPath(b.path("linker.ld"));
    b.installArtifact(kernel);

    const grub_create = GrubCreate.init(b, kernel_name);
    grub_create.step.dependOn(&kernel.step);

    const qemu = b.addSystemCommand(&.{"qemu-system-i386"});
    qemu.addArgs(&.{ "-display", "gtk", "-cdrom" });
    qemu.addFileArg(b.path(b.fmt("{s}.iso", .{kernel_name})));
    qemu.step.dependOn(&grub_create.step);

    const run = b.step("run", "build, make .iso and run with qemu-system-i386");
    run.dependOn(&qemu.step);
}

const GrubCreate = struct {
    step: std.Build.Step,
    file: []const u8,

    pub fn init(owner: *std.Build, file: []const u8) *GrubCreate {
        const grub_create = owner.allocator.create(GrubCreate) catch @panic("OOM");
        grub_create.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "grub creating ISO",
                .owner = owner,
                .makeFn = &grub_install,
            }),
            .file = file,
        };
        return grub_create;
    }

    fn grub_install(step: *std.Build.Step, options: std.Progress.Node) !void {
        const self: *GrubCreate = @fieldParentPtr("step", step);
        const progress = options.start("installing...", 5);

        const b = step.owner;
        const cwd = std.fs.cwd();
        const build_dir = try cwd.makeOpenPath(b.exe_dir, .{});

        const iso = try cwd.makeOpenPath("iso/", .{});
        try iso.makePath("boot/grub/");
        const iso_boot = try iso.openDir("boot/", .{});
        const iso_boot_grub = try iso_boot.openDir("grub/", .{});
        progress.completeOne();

        try build_dir.copyFile(self.file, iso_boot, self.file, .{});
        progress.completeOne();

        try iso.copyFile("grub.cfg", iso_boot_grub, "grub.cfg", .{});
        progress.completeOne();

        const iso_name = b.fmt("{s}.iso", .{self.file});

        _ = b.run(
            &.{ "grub-mkrescue", "-o", iso_name, "iso/" },
        );
        progress.completeOne();
        progress.end();
    }
};
