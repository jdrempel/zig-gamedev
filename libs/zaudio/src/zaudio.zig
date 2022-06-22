const std = @import("std");
const c = @cImport(@cInclude("miniaudio.h"));

pub const EngineConfig = c.ma_engine_config;

pub const Engine = struct {
    handle: *c.ma_engine,

    pub fn init(allocator: std.mem.Allocator, config: ?*const EngineConfig) Error!Engine {
        var handle = allocator.create(c.ma_engine) catch return error.OutOfMemory;
        errdefer allocator.destroy(handle);

        try checkResult(c.ma_engine_init(config, handle));

        return Engine{ .handle = handle };
    }

    pub fn deinit(engine: Engine, allocator: std.mem.Allocator) void {
        c.ma_engine_uninit(engine.handle);
        allocator.destroy(engine.handle);
    }

    pub fn readPcmFrames(engine: Engine, comptime T: type, frames: []T, frames_read: ?*u64) Error!void {
        try checkResult(c.ma_engine_read_pcm_frames(engine.handle, frames.ptr, frames.len, frames_read));
    }

    pub fn getTime(engine: Engine) u64 {
        return c.ma_engine_get_time(engine.handle);
    }

    pub fn setTime(engine: Engine, global_time: u64) Error!void {
        try checkResult(c.ma_engine_set_time(engine.handle, global_time));
    }

    pub fn getChannels(engine: Engine) u32 {
        return c.ma_engine_get_channels(engine.handle);
    }

    pub fn getSampleRate(engine: Engine) u32 {
        return c.ma_engine_get_sample_rate(engine.handle);
    }

    pub fn start(engine: Engine) Error!void {
        try checkResult(c.ma_engine_start(engine.handle));
    }

    pub fn stop(engine: Engine) Error!void {
        try checkResult(c.ma_engine_stop(engine.handle));
    }

    pub fn setVolume(engine: Engine, volume: f32) Error!void {
        try checkResult(c.ma_engine_set_volume(engine.handle, volume));
    }

    pub fn setGainDb(engine: Engine, gain_db: f32) Error!void {
        try checkResult(c.ma_engine_set_gain_db(engine.handle, gain_db));
    }

    pub fn getNumListeners(engine: Engine) u32 {
        return c.ma_engine_get_listener_count(engine.handle);
    }

    pub fn findClosestListener(engine: Engine, absolute_pos_xyz: [3]f32) u32 {
        return c.ma_engine_find_closest_listener(
            engine.handle,
            absolute_pos_xyz[0],
            absolute_pos_xyz[1],
            absolute_pos_xyz[2],
        );
    }

    pub fn setListenerPosition(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_position(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerPosition(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_position(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerDirection(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_direction(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerDirection(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_direction(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerVelocity(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_velocity(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerVelocity(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_velocity(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerWorldUp(engine: Engine, index: u32, v: [3]f32) void {
        c.ma_engine_listener_set_world_up(engine.handle, index, v[0], v[1], v[2]);
    }
    pub fn getListenerWorldUp(engine: Engine, index: u32) [3]f32 {
        const v = c.ma_engine_listener_get_world_up(engine.handle, index);
        return .{ v.x, v.y, v.z };
    }

    pub fn setListenerEnabled(engine: Engine, index: u32, enabled: bool) void {
        c.ma_engine_listener_set_enabled(engine.handle, index, if (enabled) 1 else 0);
    }
    pub fn isListenerEnabled(engine: Engine, index: u32) bool {
        return c.ma_engine_listener_is_enabled(engine.handle, index) == 1;
    }

    pub fn setListenerCone(
        engine: Engine,
        index: u32,
        inner_radians: f32,
        outer_radians: f32,
        outer_gain: f32,
    ) void {
        c.ma_engine_listener_set_cone(engine.handle, index, inner_radians, outer_radians, outer_gain);
    }
    pub fn getListenerCone(
        engine: Engine,
        index: u32,
        inner_radians: ?*f32,
        outer_radians: ?*f32,
        outer_gain: ?*f32,
    ) void {
        c.ma_engine_listener_get_cone(engine.handle, index, inner_radians, outer_radians, outer_gain);
    }
};

pub const Error = error{
    GenericError,
    InvalidArgs,
    InvalidOperation,
    OutOfMemory,
};

fn checkResult(result: c.ma_result) Error!void {
    // TODO: Handle all errors.
    if (result != c.MA_SUCCESS)
        return error.GenericError;
}

const expect = std.testing.expect;

test "zaudio.engine.basic" {
    const engine = try Engine.init(std.testing.allocator, null);
    defer engine.deinit(std.testing.allocator);

    var frames: [2]f32 = undefined;
    try engine.readPcmFrames(f32, frames[0..], null);

    try engine.setTime(engine.getTime());

    std.debug.print("Channels: {}, SampleRate: {}, NumListeners: {}, ClosestListener: {}\n", .{
        engine.getChannels(),
        engine.getSampleRate(),
        engine.getNumListeners(),
        engine.findClosestListener(.{ 0.0, 0.0, 0.0 }),
    });

    try engine.start();
    try engine.stop();
    try engine.start();
    try engine.setVolume(1.0);
    try engine.setGainDb(1.0);

    engine.setListenerEnabled(0, true);
    try expect(engine.isListenerEnabled(0) == true);
}