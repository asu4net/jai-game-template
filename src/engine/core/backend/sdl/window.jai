#import "SDL3";

Window :: struct {
    handle : *SDL_Window;
    width  : int;
    height : int;
    vsync  : bool;
}

init_window :: (using window: *Window, name := "game", w := 1280, h := 720, v := true) -> bool {
    handle = SDL_CreateWindow(name.data, xx w, xx h, SDL_WINDOW_OPENGL);
    
    if !handle {
        log_error("Failed to create the window.");
        return false;
    }

    width  = w;
    height = h;
    vsync  = v;

    SDL_SetWindowResizable(handle, true);
    SDL_GL_SetSwapInterval(xx vsync);
    
    return true;
}

deinit_window :: (using window: *Window) {
    SDL_DestroyWindow(handle);
}

swap_buffers :: inline (using window: *Window)  {
    SDL_GL_SwapWindow(handle);
}

// *** refactor from here ***.

is_key_down :: inline (input: SDL_Scancode) -> bool {
    numkeys : s32;
    kb_state := SDL_GetKeyboardState(*numkeys);
    return kb_state[input];
}

SDL_BUTTON_LMASK :: 1 << 0;
SDL_BUTTON_MMASK :: 1 << 1;
SDL_BUTTON_RMASK :: 1 << 2;

is_mouse_button_down :: (mask: u32) -> bool {
    state := SDL_GetMouseState(null, null);
    return (state & mask) != 0;
}

get_mouse_pos :: inline () -> Vector2 {
    using state: Vector2;
    SDL_GetMouseState(*x, *y);
    return state;
}

process_window_events :: (using window: *Window, done: *bool) {
    event: SDL_Event;
    while SDL_PollEvent(*event) {
        #if IMGUI then process_imgui_events(*event);
        if event.type == {
            case xx SDL_EventType.WINDOW_RESIZED;
            {
                width  = event.window.data1;
                height = event.window.data2;
            }
            case xx SDL_EventType.QUIT;
            {
                done.* = true;
            }
            case xx SDL_EventType.KEY_DOWN;
            {
                #if DEBUG
                then if event.key.key == SDLK_ESCAPE then done.* = true;
            }
            case;
        }
    }
}