const std = @import("std");
const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = addChipmunk(b, target, optimize);
    b.installArtifact(lib);

    const example = b.addExecutable(.{
        .name = "Hello World Example",
        .optimize = optimize,
        .target = target,
        .root_source_file = .{ .path = "src/example.zig" },
    });
    example.linkLibrary(lib);

    const run_example = b.addRunArtifact(example);

    const run_example_step = b.step("example", "Run hello world example");
    run_example_step.dependOn(&run_example.step);

    //const main_tests = b.addTest(.{
    //    .root_source_file = .{ .path = "src/main.zig" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //main_tests.linkLibrary(lib);

    //const run_main_tests = b.addRunArtifact(main_tests);

    //const test_step = b.step("test", "Run library tests");
    //test_step.dependOn(&run_main_tests.step);
}

pub fn addChipmunk(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const cp_repo = GitRepoStep.create(b, .{
        .url = "https://github.com/slembcke/Chipmunk2D",
        .branch = "Chipmunk-7.0.3",
        .sha = "87340c216bf97554dc552371bbdecf283f7c540e",
    });

    const lib = b.addStaticLibrary(.{
        .name = "Chipmunk2D-zig",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.step.dependOn(&cp_repo.step);

    lib.addIncludePath(.{
        .path = chipPath(b, cp_repo, &.{"include"}),
    });

    const c_flags_default = &.{
        "-std=gnu99",
        "-ffast-math",
        "-Wall",
    };

    const c_flags_nondebug = &.{
        "-DNDEBUG",
    };

    const c_flags: []const []const u8 = if (optimize != .Debug) (std.mem.concat(b.allocator, []const u8, &.{ c_flags_default, c_flags_nondebug }) catch @panic("OOM")) else c_flags_default;

    lib.addCSourceFiles(&.{
        chipPath(b, cp_repo, &.{ "src", "chipmunk.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpArbiter.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpArray.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpBBTree.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpBody.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpCollision.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpConstraint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpDampedRotarySpring.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpDampedSpring.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpGearJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpGrooveJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpHashSet.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpHastySpace.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpMarch.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpPinJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpPivotJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpPolyShape.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpPolyline.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpRatchetJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpRobust.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpRotaryLimitJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpShape.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSimpleMotor.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSlideJoint.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpace.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpaceComponent.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpaceDebug.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpaceHash.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpaceQuery.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpaceStep.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSpatialIndex.c" }),
        chipPath(b, cp_repo, &.{ "src", "cpSweep1D.c" }),
    }, c_flags);

    lib.installHeadersDirectory(chipPath(b, cp_repo, &.{ "include", "chipmunk" }), "chipmunk");

    return lib;
}

fn chipPath(b: *std.Build, cp_repo: *GitRepoStep, comptime paths: []const []const u8) []u8 {
    return std.fs.path.join(b.allocator, .{cp_repo.path} ++ paths) catch @panic("OOM");
}
