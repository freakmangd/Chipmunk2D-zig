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

pub fn addChipmunk(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const cp_repo = GitRepoStep.create(b, .{
        .url = "https://github.com/slembcke/Chipmunk2D",
        .branch = "master",
        .sha = "d0239ef4599b3688a5a336373f7d0a68426414ba",
    });

    const lib = b.addStaticLibrary(.{
        .name = "Chipmunk2D-zig",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.step.dependOn(&cp_repo.step);

    lib.addIncludePath(.{
        .path = chipPath(b, &lib.step, cp_repo, &.{"include"}),
    });

    const c_flags_default = &.{
        "-std=gnu99",
        "-ffast-math",
        "-Wall",
    };

    const c_flags_nondebug = &.{
        "-DNDEBUG",
    };

    const c_flags: []const []const u8 = if (optimize != .Debug)
        (std.mem.concat(b.allocator, []const u8, &.{ c_flags_default, c_flags_nondebug }) catch @panic("OOM"))
    else
        c_flags_default;

    lib.addCSourceFiles(.{
        .root = .{ .path = cp_repo.path },
        .files = &.{
            "src/chipmunk.c",
            "src/cpArbiter.c",
            "src/cpArray.c",
            "src/cpBBTree.c",
            "src/cpBody.c",
            "src/cpCollision.c",
            "src/cpConstraint.c",
            "src/cpDampedRotarySpring.c",
            "src/cpDampedSpring.c",
            "src/cpGearJoint.c",
            "src/cpGrooveJoint.c",
            "src/cpHashSet.c",
            "src/cpHastySpace.c",
            "src/cpMarch.c",
            "src/cpPinJoint.c",
            "src/cpPivotJoint.c",
            "src/cpPolyShape.c",
            "src/cpPolyline.c",
            "src/cpRatchetJoint.c",
            "src/cpRobust.c",
            "src/cpRotaryLimitJoint.c",
            "src/cpShape.c",
            "src/cpSimpleMotor.c",
            "src/cpSlideJoint.c",
            "src/cpSpace.c",
            "src/cpSpaceComponent.c",
            "src/cpSpaceDebug.c",
            "src/cpSpaceHash.c",
            "src/cpSpaceQuery.c",
            "src/cpSpaceStep.c",
            "src/cpSpatialIndex.c",
            "src/cpSweep1D.c",
        },
        .flags = c_flags,
    });

    lib.installHeadersDirectory(chipPath(b, &lib.step, cp_repo, &.{ "include", "chipmunk" }), "chipmunk");

    return lib;
}

fn chipPath(b: *std.Build, step: *const std.Build.Step, cp_repo: *GitRepoStep, comptime paths: []const []const u8) []u8 {
    return std.fs.path.join(b.allocator, .{cp_repo.getPath(step)} ++ paths) catch @panic("OOM");
}
