#load "src/engine.jai";

main :: () {
    engine_run(width = 1920, height = 1080);
    defer engine_shutdown();

    anim: Atlas_Animation;
    anim.loop = true;

    pos: Vector2;
    while engine_keep_running() {
        if is_key_down(.LEFT) {
            pos += LEFT_2D * 1.5 * delta_seconds();
        }
        if is_key_down(.RIGHT) {
            pos += RIGHT_2D * 1.5 * delta_seconds();
        }
        atlas_animation_step(*anim);
        draw_atlas_quad(make_matrix(pos, 0, 20 * ONE_2D), img = anim.current);    
        
        #if IMGUI {
            ImGui.Begin("Animation");
            ImGui.Text("Time: %", anim.time);
            ImGui.Text("Duration: %", anim.step);
            ImGui.Text("Current: %", anim.current);
            ImGui.End();
        }
    }
}