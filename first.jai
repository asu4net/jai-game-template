#load "src/engine.jai";

pos: Vector2;
anim: Atlas_Animation;

main :: () {
    run_app(name = "Game?", width = 1920, height = 1080);
    defer end_app();
    anim.loop = true;

    while keep_running() {
        defer swap_buffers();
        
        if is_key_down(.LEFT) {
        pos += LEFT_2D * 1.5 * frame_time();
        }
        if is_key_down(.RIGHT) {
            pos += RIGHT_2D * 1.5 * frame_time();
        }
        atlas_animation_step(*anim);     
        
        draw_frame(() { 
            draw_atlas_quad(make_matrix(pos, 0, 20 * ONE_2D), img = anim.current);
        });
        
        draw_imgui(() {
            imgui_begin("Animation");
            imgui_text("Time: %", anim.time);
            imgui_text("Duration: %", anim.step);
            imgui_text("Current: %", anim.current);
            imgui_end();
        });
    }
}