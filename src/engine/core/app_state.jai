App_State :: struct {
    done          : bool;
    window        : *SDL_Window;
    screen_w      : int;
    screen_h      : int;
    gl_ctx        : SDL_GLContext;
    fb            : Frame_Buffer;
    fb_tex        : Texture;
    drawing_frame : bool;
}

#add_context app: *App_State;

#run #if !DEBUG then disable_runtime_console();

run_app :: (name := "game", width := 1280, height := 720, vsync := true) -> bool {

    if context.app then end_app();
    context.app = New(App_State);
    using app := context.app;
    
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    
    sdl_inited := SDL_Init(SDL_INIT_VIDEO);
    if !sdl_inited {
        log_error("Failed to init SDL.");
        return false;
    }
    
    window = SDL_CreateWindow(name.data, xx width, xx height, SDL_WINDOW_OPENGL);
    
    if !window {
        log_error("Failed to create the window.");
        return false;
    }
    
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, value = 4);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, value = 4);

    gl_ctx = SDL_GL_CreateContext(window);

    if !gl_ctx {
        log_error("Failed to create the OpenGL context.");
        return false;
    }
    
    SDL_SetWindowResizable(window, true);
    screen_w = width;
    screen_h = height;
    
    SDL_GL_MakeCurrent(window, gl_ctx);
    SDL_GL_SetSwapInterval(xx vsync);
    gl_load(*gl, xx SDL_GL_GetProcAddress);

    #if DEBUG {
        log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
        log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
        gl_enable_debug_output(break_on_error = true);
        DumpGLErrors(tag = "context");
    }

    SDL_GL_SetSwapInterval(1);
    set_clear_color(DARK_GREY);

    #if IMGUI then imgui_init(window, *gl_ctx);
    init_renderer2d();

    // Frame buffer
    init_frame_buffer(*fb, .{
        width  = width,
        height = height,
        attachments = .[ .{.RGBA8}, .{.RED_INTEGER}, .{.DEPTH24STENCIL8} ]
    });

    // This is a bit hacky, sorry.
    fb_tex.id = fb.color_attachments[0];
    fb_tex.width =  xx width;
    fb_tex.height = xx height;

    return true;
}

keep_running :: () -> bool {
    process_window_events();
    // Update viewport size.
    camera := *context.renderer2d.camera;
    camera.viewport_w = context.app.screen_w;
    camera.viewport_h = context.app.screen_h;
    // Update deltatime.
    time_step();
    return !context.app.done;
}

draw_scope :: () {
    drawing_frame := context.app.drawing_frame; 
    if !drawing_frame {
        // Start using the frame buffer before drawing.
        bind_frame_buffer(*context.app.fb);
        // Clear last frame buffer.
        clear_screen(); 
    } else {
        // Draw all the stuff to the frame buffer.
        flush_renderer2d();
        // Stop using the frame buffer.
        unbind_frame_buffer();
        // Prepare the frame buffer quad.
        draw_gui_quad(tex = *context.app.fb_tex, flags = GUIQuadFlag.NONE); 
        // Draw the frame buffer quad to the screen buffer.
        flush_renderer2d();
    }
    context.app.drawing_frame = !drawing_frame;
}

end_app :: () {
    using app := context.app;
    if !app then return;
    context.app = null;
    // This texture is managed by the fb, there is no need to delete it.
    Initialize(*fb_tex);
    deinit_frame_buffer(*fb);
    deinit_renderer2d();
    #if IMGUI then imgui_deinit();
    SDL_DestroyWindow(window);
    SDL_Quit();
    free(app);
    #if DEBUG then report_memory_leaks();
}

is_key_down :: inline (input : SDL_Scancode) -> bool {
    numkeys : s32;
    kb_state := SDL_GetKeyboardState(*numkeys);
    return kb_state[input];
}

swap_buffers :: inline () {
    SDL_GL_SwapWindow(context.app.window);
}

#scope_file

#import "SDL3";

process_window_events :: inline () {
    using app := context.app;
    event: SDL_Event;
    while SDL_PollEvent(*event) {
        #if IMGUI then imgui_process_events(*event);
        if event.type == {
            case xx SDL_EventType.WINDOW_RESIZED;
            {
                screen_w  = event.window.data1;
                screen_h = event.window.data2;
            }
            case xx SDL_EventType.QUIT;
            {
                done = true;
            }
            case xx SDL_EventType.KEY_DOWN;
            {
                #if DEBUG
                then if event.key.key == SDLK_ESCAPE then done = true;
            }
            case;
        }
    }   
}