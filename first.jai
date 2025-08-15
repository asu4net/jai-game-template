#load "src/engine.jai";

main :: () {
    using app_callbacks();
    begin = game_begin; 
    end   = game_end;
    tick  = game_tick;
    run_app(name = "The Goblin Game", editor_play_directly = true);
}

goblin: Entity;

game_begin :: () {
    goblin = dlz_entity_from_file("goblin");
    play_atlas_animation(goblin);
}

game_tick :: () {
    if get_pixel_id() == goblin.(int) && is_mouse_button_down(.L) {
        set_pos(goblin, get_mouse_world_pos());
    }
}

game_end :: () {
    destroy_entity(goblin);
}