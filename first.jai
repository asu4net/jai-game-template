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

        tick_app();

        atlas_animation_step(*anim);     
        
        if performed(.TOGGLE_PLAY) {
            print("Yayyy!");
        }

        draw_frame(() {
            draw_quad(.{ transform = make_matrix(goblin_pos), size = .{ 10, 10 }, image = anim.current, pixel_id = 1 });
            
            if get_pixel_id() == 1 && is_mouse_button_down(.L) {
                goblin_pos = get_mouse_world_pos();
            }
        });
        
        #if IMGUI {
            draw_imgui(() {
                imgui_begin("Goblin");
                imgui_text("Time: %", anim.time);
                imgui_text("Duration: %", anim.step);
                imgui_text("Current: %", anim.current);
                imgui_text("Selected: %", get_pixel_id());
                imgui_text("Pos: %", goblin_pos);
                imgui_end();
                
                #if EDITOR {
                    draw_editor();
                }
            });
        }
    }
}