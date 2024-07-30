const Build = @import("std").Build;
const Target = @import("std").Target;
const Cross = @import("std").zig.CrossTarget;

pub fn build(b: *Build) void {
    // const target = Target{ .os = .{ .tag = Target.Os.Tag.freestanding, .version_range = .{} }, .abi = Target.Abi.none, .cpu = Target.Cpu.Arch.x86 };
    // const cross = Target{ .os = .{ .tag = Target.Os.Tag.freestanding, .version_range = .{ .none = Target.Os.VersionRange.default(.freestanding, .x86) } }, .abi = Target.Abi.none, .cpu = Target.Cpu.Arch.x86 };
    const target = b.resolveTargetQuery(.{ .cpu_arch = .x86, .os_tag = .freestanding });

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .target = target,
        .root_source_file = b.path("src/main.zig"),
    });

    kernel.setLinkerScriptPath(Build.LazyPath{ .src_path = .{ .owner = b, .sub_path = "linker.ld" } });
    b.installArtifact(kernel);
}
