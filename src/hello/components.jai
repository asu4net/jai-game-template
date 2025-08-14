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
    idle_step  : f32;
    run_step   : f32;
}

tick_character_components :: () {
    view := get_entity_view(Character_Component, Movement2D_Component, Atlas_Animation_Component, Sprite_Component);
    for entity: view {
        character  := get_component(Character_Component, entity);
        movement   := get_component(Movement2D_Component, entity);
        atlas_anim := get_component(Atlas_Animation_Component, entity);
        
        // Slot 0 is for gun
        gun_entity := get_child_at(0, entity); 
        gun: *Gun_Component;
        if gun_entity != NULL_ENTITY && has_component(Gun_Component, gun_entity) {
            gun = get_component(Gun_Component, gun_entity);
        }
        
        // If is the player lets just poll the input
        if character.is_player {
            movement.has_target = false;
            movement.dir = compute_input_dir(); 

            // Player gun handling
            if gun then gun.dir = compute_mouse_input_dir(get_pos(entity));
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
        
        state := compute_animation_state(ifx gun then gun.dir else character.last_dir, stopped);
        if state != character.curr_state {
            character.curr_state = state;
            play_animation(entity, state);
        }
    }
}

#scope_file

compute_input_dir :: () -> Vector2 {
    using dir: Vector2;
    if is_key_down(.W) y += 1; 
    if is_key_down(.S) y -= 1; 
    if is_key_down(.A) x -= 1; 
    if is_key_down(.D) x += 1;
    dir = normalize(dir);  
    return dir;
}

compute_mouse_input_dir :: (center: Vector2) -> Vector2 {
    mouse_pos := get_mouse_world_pos();
    dir := normalize(mouse_pos - center);
    return dir;
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
    else return .LOOK_R;
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

#scope_export

Gun_Component :: struct @Component {
    dir: Vector2; @JsonIgnore
    angle: f32; @JsonIgnore
    hand_offset: f32;
    visuals_offset: f32;
}

tick_gun_components :: () {
    view := get_entity_view(Gun_Component, Transform2D_Component);
    for entity: view {
        tick_gun_entity_rotation(entity);        
    }
}

tick_gun_entity_rotation :: (entity: Entity) {
    gun := get_component(Gun_Component, entity);
    raw_ang := atan2(gun.dir.y, gun.dir.x) * DEG_PER_RAD;
    gun.angle = raw_ang;
    if gun.angle < 0 then gun.angle += 360;
    left_side := gun.angle > 90 && gun.angle < 270;
    if left_side then gun.angle += 180;
    set_ang(entity, gun.angle);
    // between 90 and 270 we want to flip the weapon sprite
    // we are going to asume that the first child of gun is the visual
    gun_visuals := get_child_at(entity, 0);
    if gun_visuals != NULL_ENTITY {
        sprite := get_component(Sprite_Component, gun_visuals);
        sprite.flip_x = left_side;
        pos := get_pos(gun_visuals);
        pos.x = ifx left_side then -gun.visuals_offset else gun.visuals_offset; 
        set_pos(gun_visuals, pos);
    }
    pos := get_pos(entity);
    pos.x = ifx left_side then -gun.hand_offset else gun.hand_offset;
    set_pos(entity, pos);
    // Asuming owner is the parent....
    owner := get_parent(entity);
    if owner != NULL_ENTITY {
        owner_sprite := get_component(Sprite_Component, owner);
        gun_sprite := get_component(Sprite_Component, gun_visuals);
        if gun_visuals != NULL_ENTITY {
            //print("Raw ang %\n", raw_ang);
            is_up := raw_ang > 0; 
            gun_sprite.layer = ifx is_up 
                then owner_sprite.layer - 1 
                else owner_sprite.layer + 1;
        }    
    }
}