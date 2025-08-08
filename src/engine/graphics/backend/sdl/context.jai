Graphics_Context :: SDL_GLContext;

create_graphics_context :: (window: *void) -> Graphics_Context {

    sdl_inited := SDL_Init(SDL_INIT_VIDEO);
    
    if !sdl_inited {
        log_error("Failed to init SDL.");
        return null;
    }

    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, value = 4);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, value = 4);
    
    window_handle: *SDL_Window = xx window;

    c := SDL_GL_CreateContext(window_handle);
    if !c {
        log_error("Failed to create the OpenGL context.");
        return null;
    }
    SDL_GL_MakeCurrent(window_handle, c);
    gl_load(*gl, xx SDL_GL_GetProcAddress);

    #if DEBUG {
        log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
        log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
        gl_enable_debug_output(break_on_error = true);
        DumpGLErrors(tag = "context");
    }
    return c;
}

destroy_graphics_context :: inline (c: *Graphics_Context) {
    SDL_Quit();
}

#scope_file

#import "SDL3";