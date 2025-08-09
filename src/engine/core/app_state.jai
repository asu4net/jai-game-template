Attachment :: enum u8 {
    COLOR;
    PX_ID;
    DEPTH;
}

App_State :: struct {
    done     : bool;
    window   : Window;
    g_ctx    : Graphics_Context;
    screen_w : int;
    screen_h : int;
    fb       : Frame_Buffer;
    fb_tex   : Texture;
    pixel_id : int;
}

#add_context app: *App_State;
get_app :: inline () => context.app;
set_app :: inline (app: *App_State) { context.app = app; };
is_app  :: inline () => context.app != null; 

#run #if !DEBUG then disable_runtime_console();

run_app :: (name := "game", width := 1280, height := 720, vsync := true) -> bool {
    if is_app() then end_app();
    set_app(New(App_State));
    using app := get_app();
    
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    init_window(*window, name, width, height, vsync);
    g_ctx = create_graphics_context(window.handle);

    screen_w = width;
    screen_h = height;
    
    #if IMGUI then imgui_init(window, g_ctx);
    init_renderer2d();

    // Frame buffer
    init_frame_buffer(*fb, .{
        width  = width,
        height = height,
        attachments = .[ .{.RGBA8}, .{.RED_INTEGER}, .{.DEPTH24STENCIL8} ]
    });
    
    // This is a bit hacky, sorry.
    fb_tex.id = fb.color_attachments[0];
    fb_tex.spec.width =  xx width;
    fb_tex.spec.height = xx height;

    return true;
}

keep_running :: () -> bool {
    using app := get_app();
    process_window_events(*window, *done);
    // Update viewport size.
    if screen_w != window.width || screen_h != window.height {
        screen_w = window.width;
        screen_h = window.height;
        resize_frame_buffer(*fb, screen_w, screen_h);
    }
    camera := *context.renderer2d.camera;
    camera.viewport_w = screen_w;
    camera.viewport_h = screen_h;
    // Update frametime.
    time_step();
    return !app.done;
}

draw_frame :: inline (proc: ()) {
    using app := get_app();
    // Start using the frame buffer before drawing.
    bind_frame_buffer(*fb);
    // Clear screen.
    clear_screen_buffer();
    // Clear last frame buffer.
    clear_frame_buffer_attachment(*fb, xx Attachment.PX_ID);
    // User draw.
    proc();
    // Draw all the stuff to the frame buffer.
    flush_renderer2d();
    // Read the cursor pixel id.
    mouse_pos := get_mouse_pos();
    mouse_pos.y = screen_h - mouse_pos.y - 1;
    pixel_id = read_pixel(*fb, xx Attachment.PX_ID, mouse_pos);
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
    set_app(null);
    // This texture is managed by the fb, there is no need to delete it.
    Initialize(*fb_tex);
    deinit_frame_buffer(*fb);
    deinit_renderer2d();
    #if IMGUI then imgui_deinit();
    destroy_graphics_context(*g_ctx);
    free(app);
    #if DEBUG then report_memory_leaks();
    return true;
}

end_frame :: inline () {
    using app := get_app();
    reset_temporary_storage();
    swap_buffers(*window);
}