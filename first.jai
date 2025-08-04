#load "src/engine.jai";

main :: () {
    engine_run();
    defer engine_shutdown();

    pos: Vector2;
    while engine_keep_running() {
        if is_key_down(.LEFT) {
            pos += LEFT_2D * 1.5 * delta_seconds();
        }
        if is_key_down(.RIGHT) {
            pos += RIGHT_2D * 1.5 * delta_seconds();
        }
        draw_quad(make_matrix(pos + UP_2D), tint = LIGHT_RED);
        #if COMP_TIME_ATLAS {
            draw_atlas_quad(make_matrix(pos, 0, 20 * ONE_2D), img = .GOBLIN_IDLE_0, tint = LIGHT_GREEN);    
            draw_atlas_quad(make_matrix(pos + RIGHT_2D, 0, 20 * ONE_2D), img = .GOBLIN_IDLE_1, tint = LIGHT_BLUE);  
        }
    }
}