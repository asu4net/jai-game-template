#load "src/engine.jai";

main :: () {
    using app_callbacks();
    begin = begin_play; 
    end   = end_play;
    tick  = tick_game;
    run_app(name = "Game?");
}

goblin: Entity;

begin_play :: () {
    goblin = dlz_entity_from_file("assets/goblin.prefab");
    get_component(Atlas_Animation_Component, goblin).playing = true;
}

tick_game :: () {
    if get_pixel_id() == goblin.(int) && is_mouse_button_down(.L) {
        set_pos(goblin, get_mouse_world_pos());
    }
}

end_play :: () {
    destroy_entity(goblin);
}