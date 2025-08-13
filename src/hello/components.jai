Animation_State :: enum {
    LOOK_R;
    LOOK_L;
    LOOK_F;
    LOOK_B;
    
    RUN_L;
    RUN_R;
    RUN_F;
    RUN_B;
    COUNT;
}

Animation_Node :: struct {
    state : Animation_State;
    start : Atlas_Image;
    end   : Atlas_Image;
    flip  : bool;
}

Character_Component :: struct @Component {
    animation_nodes: [Animation_State.COUNT] Animation_Node; 
    curr_state : Animation_State; @JsonIgnore
    last_dir   : Vector2; @JsonIgnore
    is_player  : bool;
    idle_step  : f32 = 0.5;
    run_step   : f32 = 0.15;
}

play_animation :: (entity: Entity, state: Animation_State) {
    if state == .COUNT return;
    using get_component(Character_Component,  entity);
    sprite := get_component(Sprite_Component, entity);
    for animation_nodes {
        if it.state != state then continue;
        play_atlas_animation(entity, it.start, it.end);
        sprite.flip_x = it.flip;
        return;
    }
}

tick_character_components :: () {
    view := get_entity_view(Character_Component, Movement2D_Component, Atlas_Animation_Component, Sprite_Component);
    for entity: view {
        character  := get_component(Character_Component, entity);
        movement   := get_component(Movement2D_Component, entity);
        atlas_anim := get_component(Atlas_Animation_Component, entity);
        
        // If is the player lets just poll the input
        if character.is_player {
            using dir: Vector2;
            if is_key_down(.W) y += 1; 
            if is_key_down(.S) y -= 1; 
            if is_key_down(.A) x -= 1; 
            if is_key_down(.D) x += 1;
            dir = normalize(dir);
            movement.has_target = false;
            movement.dir = dir; 
        }
        
        eps :: 0.001;
        
        stopped: bool;
        if abs(movement.dir.x) > eps || abs(movement.dir.y) > eps {
            stopped = false;
            character.last_dir = movement.dir;
        } else {
            stopped = true;
        }

        atlas_anim.step = ifx stopped then character.idle_step else character.run_step; 

        state := compute_animation_state(character.last_dir, stopped);
        if state != character.curr_state {
            character.curr_state = state;
            play_animation(entity, state);
        }
    }
}

// This procedure is an abobination but I don't care that much.
compute_animation_state :: (dir: Vector2, stopped: bool) -> Animation_State {
    angle := atan2(dir.y, dir.x) * DEG_PER_RAD;
    if angle < 0 then angle += 360;
    if      angle >= 337.5 || angle < 22.5 return ifx stopped then .LOOK_R else .RUN_R;
    else if angle < 67.5                   return ifx stopped then .LOOK_R else .RUN_R;
    else if angle < 112.5                  return ifx stopped then .LOOK_B else .RUN_B;
    else if angle < 157.5                  return ifx stopped then .LOOK_L else .RUN_L;
    else if angle < 202.5                  return ifx stopped then .LOOK_L else .RUN_L;
    else if angle < 247.5                  return ifx stopped then .LOOK_L else .RUN_L;
    else if angle < 292.5                  return ifx stopped then .LOOK_F else .RUN_F;
    return .LOOK_B;
}