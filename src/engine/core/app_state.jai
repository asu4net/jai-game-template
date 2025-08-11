Attachment :: enum u8 {
    COLOR;
    PX_ID;
    DEPTH;
}

App_State :: struct {
    done        : bool;
    window      : Window;
    g_ctx       : Graphics_Context;
    viewport    : Vector2;
    fb          : Frame_Buffer;
    fb_tex      : Texture;
    pixel_id    : int;
    clear_color : Vector4;
}

#add_context app: *App_State;
get_app :: inline () => context.app;
set_app :: inline (app: *App_State) { context.app = app; };
is_app  :: inline () => context.app != null; 

#run #if !DEBUG then disable_runtime_console();

run_app :: (name := "game", width := 1280, height := 720, vsync := true, bg_tint := DARK_GREY) -> bool {
    if is_app() then end_app();
    set_app(New(App_State));

    using app := get_app();
    clear_color = bg_tint;

    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    init_window(*window, name, width, height, vsync);
    g_ctx = create_graphics_context(window.handle);

    #if IMGUI then imgui_init(window, g_ctx);
    init_renderer2d();

    #if ECS then {
        init_entity_storage();
        init_collisions2d();
        init_damage_registry();
    }

    // Frame buffer
    update_viewport_and_frame_buffer();
    return true;
}

keep_running :: () -> bool {
    using app := get_app();
    process_window_events(*window, *done);
    update_input_actions();
    // Update viewport size.
    update_viewport_and_frame_buffer();
    // Update frametime.
    time_step();
    return !app.done;
}

#if ECS {
    tick_app :: inline (pre_collisions: () = null, post_collisions: () = null) {
        tick_timer_entities();
        move_entities();
        if pre_collisions then pre_collisions();
        tick_atlas_animations();
        query_2d_collisions();
        query_damage_collisions();
        if post_collisions then post_collisions();
    }
}

draw_frame :: inline (proc: () = null) {
    using app := get_app();
    // Start using the frame buffer before drawing.
    bind_frame_buffer(*fb);
    // Clear color buffer.
    clear_frame_buffer_color_and_depth(tint = clear_color);
    // Clear last frame buffer.
    clear_frame_buffer_attachment(*fb, xx Attachment.PX_ID);
    // ECS draw
    #if ECS {
        draw_sprite_entities();
    }
    // User draw.
    if proc then proc();
    // Draw all the stuff to the frame buffer.
    flush_renderer2d();
    // Read the cursor pixel id.
    update_pixel_id();
    // Stop using the frame buffer.
    unbind_frame_buffer();
    // Prepare the frame buffer quad.
    draw_gui_quad(tex = *fb_tex); 
    // Draw the frame buffer quad to the screen buffer.
    flush_renderer2d();
}

end_app :: () -> bool {
    if !is_app() then return false;
    using app := get_app();
    #if ECS then {
        deinit_damage_registry();
        deinit_collisions2d();
        deinit_entity_storage();
    }
    // This texture is managed by the fb, there is no need to delete it.
    Initialize(*fb_tex);
    deinit_frame_buffer(*fb);
    deinit_renderer2d();
    #if IMGUI then imgui_deinit();
    destroy_graphics_context(*g_ctx);
    set_app(null);
    free(app);
    #if DEBUG then report_memory_leaks();
    return true;
}

end_frame :: inline () {
    using app := get_app();
    #if ECS then clean_destroyed_entities();
    reset_temporary_storage();
    swap_buffers(*window);
}

// The current mouse-hovered pixel id.
get_pixel_id :: inline () -> int {
    using app := get_app();
    return pixel_id;
}

get_mouse_world_pos :: inline () -> Vector2 {
    using app := get_app();
    pv := context.renderer2d.pv_matrix_world;
    mouse_pos := get_mouse_pos();
    return screen_to_world(pv, mouse_pos, viewport);
}

#scope_file

update_pixel_id :: inline () {
    using app := get_app();
    mouse_pos := get_mouse_pos();
    mouse_pos.y = viewport.y - mouse_pos.y - 1;
    pixel_id = read_pixel(*fb, xx Attachment.PX_ID, mouse_pos);
}

update_viewport_and_frame_buffer :: () {
    using app := get_app();
    if viewport.x.(int) != window.width || viewport.y.(int) != window.height {
        using app := get_app();
        viewport.x = xx window.width;
        viewport.y = xx window.height;
        set_renderer2d_viewport(viewport);
        if !is_frame_buffer_initialized(*fb) {
            spec := Frame_Buffer.Spec.{
                width  = xx viewport.x,
                height = xx viewport.y,
                attachments = .[ .{.RGBA8}, .{.RED_INTEGER}, .{.DEPTH24STENCIL8} ]
            };
            init_frame_buffer(*fb, spec);
            // This is a bit hacky, sorry.
            fb_tex.id = fb.color_attachments[0];
            fb_tex.spec.width  = xx viewport.x;
            fb_tex.spec.height = xx viewport.y;
        }
        resize_frame_buffer(*fb, xx viewport.x, xx viewport.y);
    }
}