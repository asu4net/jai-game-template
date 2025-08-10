#import "SDL3";

is_key_down :: inline (input: Keycode) -> bool {
    numkeys : s32;
    kb_state := SDL_GetKeyboardState(*numkeys);
    return kb_state[input];
}

is_mouse_button_down :: (mouse_button: Mouse_Button) -> bool {
    state := SDL_GetMouseState(null, null);
    return (state & get_mask(mouse_button)) != 0;
}

get_mouse_pos :: inline () -> Vector2 {
    using state: Vector2;
    SDL_GetMouseState(*x, *y);
    return state;
}

#scope_file

get_mask :: (mouse_button: Mouse_Button) -> int {
    LMASK :: 1 << 0;
    MMASK :: 1 << 1;
    RMASK :: 1 << 2;
    MASKS :: int.[LMASK, MMASK, RMASK];
    if mouse_button == .COUNT then return 0;
    return MASKS[mouse_button];
}