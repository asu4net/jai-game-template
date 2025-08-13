#load "src/engine.jai";
#load "src/hello.jai";

BG_COLOR :: Vector4.{ 0.87, 0.99, 0.84, 1 };

main :: () {
    using app_callbacks();
    begin = game_begin; 
    end   = game_end;
    tick  = game_tick;
    run_app(name = "The Hello Game", bg_tint = BG_COLOR, editor_play_directly = true);
}

player: Entity;

game_begin :: () {
    player = dlz_entity_from_file("assets/player.prefab");
    play_atlas_animation(player);
}

game_tick :: () {
    tick_character_components();
}

game_end :: () {
    destroy_entity(player);
}