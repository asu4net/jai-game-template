FPS_SAMPLES :: 240;

Time :: struct {
    max_delta_time      : float64 = 0.06;
    fixed_frame_time    : float64 = 0.06;
    frame_time          : float32 = 0;
    seconds             : float64 = -1;
    frame_count         : u32 = 0;
    acc_fixed_delta     : float64 = 0;
    last_time           : float64 = 0;
    fixed_update_calls  : u32 = 0;
    scale               : float32 = 1;

    frame_times : [FPS_SAMPLES] float32;
    frame_index := 0;
    frame_total : float32;
}

#add_context time : Time;

time_step :: () {
    using context.time;
    
    // Init
    if seconds < 0 {
        last_time = get_time();
        acc_fixed_delta = fixed_frame_time;
        seconds = 0;
    }

    current_time : = get_time();
    frame_count += 1;
    time_between_frames := current_time - last_time;
    last_time = current_time;
    seconds += time_between_frames;
    frame_time = xx clamp(time_between_frames, 0, max_delta_time) * scale;
    acc_fixed_delta += xx frame_time;
    
    while acc_fixed_delta >= fixed_frame_time {
        acc_fixed_delta -= fixed_frame_time;
        fixed_update_calls += 1;
    }

    frame_total -= frame_times[frame_index];
    frame_times[frame_index] = frame_time;
    frame_total += frame_time;
    frame_index = (frame_index + 1) % FPS_SAMPLES;
}

frame_time :: () -> float32 {
    return context.time.frame_time;
}

get_time :: () -> float64 {
    one_time_init(*is_get_seconds_initialized, init_get_seconds());
    delta := current_time_monotonic() - get_seconds_base_time;
    return to_float64_seconds(delta);
}

get_frame_rate :: inline () -> float32 {
    using context.time;
    av := frame_total / FPS_SAMPLES;
    return ifx (av > 0) then (1.0 / av) else 0.0;
}

get_average_frame_rate :: inline () -> float32 {
    return (context.time.frame_count.(float64) / context.time.seconds).(float32);
}

set_time_scale :: inline (scale : float32) {
    context.time.scale = scale;
} 

#scope_module

is_get_seconds_initialized: s32;
get_seconds_base_time: Apollo_Time;

init_get_seconds :: () {
    get_seconds_base_time = current_time_monotonic();
}