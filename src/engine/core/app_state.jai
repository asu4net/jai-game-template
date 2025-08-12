Attachment :: enum u8 {
    COLOR;
    PX_ID;
    DEPTH;
}

App_State :: struct {
    done          : bool;
    window        : Window;
    g_ctx         : Graphics_Context;
    viewport      : Vector2;
    fb            : Frame_Buffer;
    fb_tex        : Texture;
    pixel_id      : int;
    clear_color   : Vector4;
    running_logic : bool;

    #if EDITOR {
        frame_by_frame : bool;
        next_frame     : bool;
        show_colliders : bool;
    }
}

#add_context app: *App_State;
get_app :: inline () => context.app;
set_app :: inline (app: *App_State) { context.app = app; };
is_app  :: inline () => context.app != null; 

Callback_Proc :: #type ();

App_Callbacks :: struct {
    draw      : Callback_Proc;
    begin     : Callback_Proc;
    end       : Callback_Proc;
    tick      : Callback_Proc;
    late_tick : Callback_Proc;

    #if IMGUI {
        draw_imgui: Callback_Proc;
    }
}

#add_context callbacks: App_Callbacks;

app_callbacks :: inline () => *context.callbacks;

#run #if !DEBUG then disable_runtime_console();

run_app :: (name := "game", width := 1280, height := 720, vsync := true, bg_tint := DARK_GREY, editor_play_directly := false) {
    if is_app() then end_app();
    set_app(New(App_State));
    #if DEBUG defer end_app();

    using app := get_app();
    clear_color = bg_tint;

    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    init_window(*window, name, width, height, vsync);
    g_ctx = create_graphics_context(window.handle);

    #if IMGUI then {
        imgui_init(window, g_ctx);
        context.imgui.callbacks.draw = context.callbacks.draw_imgui;
    }

    init_renderer2d();

    #if ECS then {
        init_entity_storage();
        init_collisions2d();
        init_damage_registry();
    }

    update_viewport_and_frame_buffer();

    cbk := app_callbacks();
    
    #if EDITOR {
        if editor_play_directly then {
            running_logic = true;
            cbk.begin();
        }
    } else {
        running_logic = true;
        cbk.begin();
    }

    while !done {
        
        time_step();
        process_window_events(*window, *done);
        update_input_actions();

        #if EDITOR {
            tick_frame_by_frame_mode();
            if performed(.TOGGLE_PLAY)
            then toggle_play();
        }
        
        if should_tick_logic() && cbk.tick 
        then cbk.tick();
        
        #if ECS {
            tick_timer_components();
            tick_atlas_animation_components();

            if should_tick_logic() {
                tick_movement_component();
                tick_collision2d_components();
                tick_damage_components();
            }
        }

        if should_tick_logic() && cbk.late_tick 
        then cbk.late_tick();

        update_viewport_and_frame_buffer();
        bind_frame_buffer(*fb);
        clear_frame_buffer_color_and_depth(tint = clear_color);
        clear_frame_buffer_attachment(*fb, xx Attachment.PX_ID);
        
        #if ECS {
            draw_sprite_entities();
        } 
        
        if cbk.draw 
        then cbk.draw();
        
        flush_renderer2d();
        
        // Update the pixel id
        mouse_pos := get_mouse_pos();
        mouse_pos.y = viewport.y - mouse_pos.y - 1;
        pixel_id = read_pixel(*fb, xx Attachment.PX_ID, mouse_pos);
        
        unbind_frame_buffer();
        draw_gui_quad(tex = *fb_tex); 
        flush_renderer2d();
        
        #if IMGUI then draw_imgui();
        
        // Cleanup
        #if ECS then clean_destroyed_entities();
        reset_temporary_storage();
        swap_buffers(*window);
    }    
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

toggle_play :: inline () {
    using get_app();
    cbk := app_callbacks();
    if !running_logic && cbk.begin then cbk.begin();
    else if cbk.end then cbk.end();
    running_logic =! running_logic;
}

#scope_file

end_app :: () -> bool {
    if !is_app() then return false;
    using app := get_app();
    
    if running_logic && context.callbacks.end   
    then context.callbacks.end();
    
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

tick_frame_by_frame_mode :: inline () {
    #if EDITOR {
        using app := get_app();
        if performed(.TOGGLE_PAUSE) {
            frame_by_frame =! frame_by_frame;
        }
        if !frame_by_frame {
            next_frame = true;
            return;
        }
        next_frame = performed(.NEXT_FRAME);   
    }
}

should_tick_logic :: inline () -> bool {
    using app := get_app();
    #if EDITOR 
    then return next_frame && running_logic;
    else return running_logic;
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