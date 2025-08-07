#load "src/engine.jai";

main :: () {
    engine_run(width = 1920, height = 1080, callbacks = .[init, null, tick, draw, draw_imgui]);
}

pos: Vector2;
anim: Atlas_Animation;

init :: () {
    anim.loop = true;
}

tick :: () {
    if is_key_down(.LEFT) {
        pos += LEFT_2D * 1.5 * delta_seconds();
    }
    if is_key_down(.RIGHT) {
        pos += RIGHT_2D * 1.5 * delta_seconds();
    }
    atlas_animation_step(*anim);
}

draw :: () {
    draw_atlas_quad(make_matrix(pos, 0, 20 * ONE_2D), img = anim.current);    
}

draw_imgui :: () {
    #if IMGUI {
        imgui_begin("Animation");
        imgui_text("Time: %", anim.time);
        imgui_text("Duration: %", anim.step);
        imgui_text("Current: %", anim.current);
        imgui_end();
    }
}