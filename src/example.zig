const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("chipmunk/chipmunk.h");
});

pub fn main() !void {
    // cpVect is a 2D vector and cpv() is a shortcut for initializing them.
    const gravity = c.cpv(0, -100);

    // Create an empty space.
    const space = c.cpSpaceNew();
    defer c.cpSpaceFree(space);
    c.cpSpaceSetGravity(space, gravity);

    // Add a static line segment shape for the ground.
    // We'll make it slightly tilted so the ball will roll off.
    // We attach it to a static body to tell Chipmunk it shouldn't be movable.
    const ground = c.cpSegmentShapeNew(c.cpSpaceGetStaticBody(space), c.cpv(-20, 5), c.cpv(-20, 5), 0);
    defer c.cpShapeFree(ground);
    c.cpShapeSetFriction(ground, 1);
    _ = c.cpSpaceAddShape(space, ground);

    // Now let's make a ball that falls onto the line and rolls off.
    // First we need to make a cpBody to hold the physical properties of the object.
    // These include the mass, position, velocity, angle, etc. of the object.
    // Then we attach collision shapes to the cpBody to give it a size and shape.

    const radius = 5;
    const mass = 1;

    // The moment of inertia is like mass for rotation
    // Use the cpMomentFor*() functions to help you approximate it.
    const moment = c.cpMomentForCircle(mass, 0, radius, c.cpvzero);

    // The cpSpaceAdd*() functions return the thing that you are adding.
    // It's convenient to create and add an object in one line.
    const ballBody = c.cpSpaceAddBody(space, c.cpBodyNew(mass, moment));
    defer c.cpBodyFree(ballBody);
    c.cpBodySetPosition(ballBody, c.cpv(0, 15));

    // Now we create the collision shape for the ball.
    // You can create multiple collision shapes that point to the same body.
    // They will all be attached to the body and move around to follow it.
    const ballShape = c.cpSpaceAddShape(space, c.cpCircleShapeNew(ballBody, radius, c.cpvzero));
    defer c.cpShapeFree(ballShape);
    c.cpShapeSetFriction(ballShape, 0.7);

    const timeStep = 1.0 / 60.0;
    var time: f32 = 0;

    // Now that it's all set up, we simulate all the objects in the space by
    // stepping forward through time in small increments called steps.
    // It is *highly* recommended to use a fixed size time step.
    while (time < 2) : (time += timeStep) {
        const pos = c.cpBodyGetPosition(ballBody);
        const vel = c.cpBodyGetVelocity(ballBody);
        std.debug.print("Time is {d:.2}. ballBody is at ({d:.2} {d:.2}). It's velocity is ({d:.2} {d:.2})\n", .{ time, pos.x, pos.y, vel.x, vel.y });

        c.cpSpaceStep(space, timeStep);
    }
}
