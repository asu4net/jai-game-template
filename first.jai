#load "src/engine.jai";

main :: () {
    c := app_callbacks();
    c.begin = begin_play; 
    c.end   = end_play;
    c.tick  = tick_game;
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