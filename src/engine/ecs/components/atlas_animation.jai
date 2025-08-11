Atlas_Animation_Component :: struct @Component {
    playing : bool = true;
    current : Atlas_Image = 0; 
    start   : Atlas_Image = 0;
    end     : Atlas_Image = xx (Atlas_Image.COUNT.(s32) - 1);
    time    : f32 = 0;
    step    : f32 = 0.1;
    loop    : bool = false;
}

tick_atlas_animations :: () {
    view := get_entity_view(Atlas_Animation_Component, Sprite_Component);
    for entity: view {
        anim   := get_component(Atlas_Animation_Component, entity);
        sprite := get_component(Sprite_Component, entity);
        atlas_animation_step(anim);
        sprite.image = anim.current;
    }
}

atlas_animation_step :: inline (using animation: *Atlas_Animation_Component) {
    if !playing then return;
    time += frame_time();
    if time < step return;
    time = 0;
    next := (current.(s32) + 1).(Atlas_Image);
    finish := (end.(s32) + 1).(Atlas_Image);
    if next != .COUNT && next != finish then {
        current = next;
        return;
    }
    current = start;
    playing = loop;
}