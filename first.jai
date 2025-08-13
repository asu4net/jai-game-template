#load "src/engine.jai";

main :: () {
    using app_callbacks();
    begin = game_begin; 
    end   = game_end;
    tick  = game_tick;
    run_app(name = "The Hello Game", editor_play_directly = true);
}

player: Entity;

game_begin :: () {
    player = dlz_entity_from_file("assets/player.prefab");
    play_atlas_animation(player);
}

game_tick :: () {
    if get_pixel_id() == player.(int) && is_mouse_button_down(.L) {
        set_pos(player, get_mouse_world_pos());
    }
}

game_end :: () {
    destroy_entity(player);
}