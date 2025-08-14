Gun_Component :: struct @Component {
    dir: Vector2; @JsonIgnore
    angle: f32; @JsonIgnore
    fire_point_pos: Vector2; @JsonIgnore
    hand_offset: f32;
    visuals_offset: f32;
}

tick_gun_components :: () {
    view := get_entity_view(Gun_Component, Transform2D_Component);
    for entity: view {
        tick_gun_entity_rotation(entity);        
    }
}

#scope_file

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
            firepoint := get_child_at(gun_visuals, 0);
            if firepoint != NULL_ENTITY {
                pos := get_pos(firepoint);
                pos.x = abs(pos.x) * ifx left_side then -1 else +1;
                set_pos(firepoint, pos);
                m := get_matrix(firepoint);
                gun.fire_point_pos = xy(m._14, m._24);
            }
        }
    }
}