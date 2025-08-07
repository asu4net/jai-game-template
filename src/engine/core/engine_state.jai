Engine_Callback_Type :: enum {
    INIT;
    DEINIT;
    TICK;
    DRAW;
    DRAW_IMGUI;
    COUNT;
}

Engine_Callback_Proc  :: #type ();
Engine_Callback_Array :: [Engine_Callback_Type.COUNT] Engine_Callback_Proc;
Engine_Callback_View  :: [] Engine_Callback_Proc;

Engine_State :: struct {
    done           : bool;
    window         : *SDL_Window;
    screen_width   : int;
    screen_height  : int;
    callback_array : Engine_Callback_Array;
    gl_ctx         : SDL_GLContext;
    fb             : Frame_Buffer;
    fb_tex         : Texture;
}

#add_context engine: *Engine_State;

#run #if !DEBUG then disable_runtime_console();

engine_run :: (app_name := "game", width := 1280, height := 720, callbacks: [] Engine_Callback_Proc = .[]) {

    if context.engine then engine_shutdown();
    context.engine = New(Engine_State);
    using state := context.engine;
    
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    
    sdl_inited := SDL_Init(SDL_INIT_VIDEO);
    if !sdl_inited {
        log_error("Failed to init SDL.");
        return;
    }
    
    window = SDL_CreateWindow(app_name.data, xx width, xx height, SDL_WINDOW_OPENGL);
    
    if !window {
        log_error("Failed to create the window.");
        return;
    }
    
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, value = 4);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, value = 4);

    gl_ctx = SDL_GL_CreateContext(window);

    if !gl_ctx {
        log_error("Failed to create the OpenGL context.");
        return;
    }

    SDL_SetWindowResizable(window, true);
    screen_width   = width;
    screen_height  = height;
    memcpy(callback_array.data, callbacks.data, callbacks.count * size_of(Engine_Callback_Proc));
    
    SDL_GL_MakeCurrent(window, gl_ctx);
    SDL_GL_SetSwapInterval(1);
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
    
    run_main_loop();
}

engine_shutdown :: () {
    using state := context.engine;
    if !state then return;
    context.engine = null;
    
    // This texture is managed by the fb, there is no need to delete it.
    Initialize(*fb_tex);
    deinit_frame_buffer(*fb);
    deinit_renderer2d();
    #if IMGUI then imgui_deinit();
    SDL_DestroyWindow(window);
    SDL_Quit();
    free(state);

    #if DEBUG {
        report_memory_leaks();
    }
}

is_key_down :: (input : SDL_Scancode) -> bool {
    numkeys : s32;
    state := SDL_GetKeyboardState(*numkeys);
    return state[input];
}

#scope_file

#import "SDL3";

invoke_callback :: inline (type: Engine_Callback_Type) -> bool {
    using engine := context.engine;
    if !engine then return false;
    proc := callback_array[xx type];
    if !proc then return false;
    proc();
    return true;
}

process_window_events :: inline () {
    using engine := context.engine;
    event: SDL_Event;
    while SDL_PollEvent(*event) {
        #if IMGUI then imgui_process_events(*event);
        if event.type == {
            case xx SDL_EventType.WINDOW_RESIZED;
            {
                screen_width  = event.window.data1;
                screen_height = event.window.data2;
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

run_main_loop :: () {
    using engine := context.engine;
    // User init.
    invoke_callback(.INIT);
    // User deinit.
    defer invoke_callback(.DEINIT); 
    // Main loop.
    while !done {
        process_window_events();
        // Update viewport size.
        camera := *context.renderer2d.camera;
        camera.viewport_w = screen_width;
        camera.viewport_h = screen_height;
        // Update deltatime.
        time_step();
        // User tick.
        invoke_callback(.TICK);
        // Start using the frame buffer before drawing.
        bind(*fb);
        // Clear last frame buffer.
        clear_screen(); 
        // User draw.
        invoke_callback(.DRAW);
        // Draw all the stuff to the frame buffer.
        flush_renderer2d();
        // Stop using the frame buffer.
        unbind(*fb);
        // Prepare the frame buffer quad.
        draw_gui_quad(tex = *fb_tex, flags = GUIQuadFlag.NONE); 
        // Draw the frame buffer quad to the screen buffer.
        flush_renderer2d();
        // Also draw imgui to the screen buffer.
        #if IMGUI {
            imgui_begin_draw();
            invoke_callback(.DRAW_IMGUI);
            imgui_end_draw();
        }
        // Swap the buffers.
        SDL_GL_SwapWindow(window);
    }
}