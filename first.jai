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
    set_pos(goblin, get_pos(goblin) + RIGHT_2D * 0.5 * frame_time());
}

end_play :: () {
    destroy_entity(goblin);
}