#load "src/engine.jai";

goblin_pos: Vector2;
anim: Atlas_Animation;
id: int;

main :: () {
    run_app(name = "Game?", width = 1920, height = 1080);
    defer end_app();
    anim.loop = true;

    while keep_running() {
        defer end_frame();
        
        atlas_animation_step(*anim);     

        // Ejemplo de uso:


        draw_frame(() {
            draw_atlas_quad(make_matrix(goblin_pos, 0, ONE_2D * 20), img = anim.current, id = 1);
            screen_size := Vector2.{ xx context.app.screen_w, xx context.app.screen_h };

            if context.app.pixel_id == 1 && is_mouse_button_down(SDL_BUTTON_LMASK) {
                goblin_pos = screen_to_world(context.renderer2d.camera.ortho_world, get_mouse_pos(), screen_size);
            }
        });
        
        draw_imgui(() {
            imgui_begin("Goblin");
            imgui_text("Time: %", anim.time);
            imgui_text("Duration: %", anim.step);
            imgui_text("Current: %", anim.current);
            imgui_text("Selected: %", context.app.pixel_id);
            imgui_text("Pos: %", goblin_pos);
            imgui_end();
        });
    }
}