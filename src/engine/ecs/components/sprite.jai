Sprite_Component :: struct @Component {
    visible  := true;
    image    := Atlas_Image.COUNT;
    tint     := WHITE;       @Color
    size     := ONE_2D;
    tiling   := ONE_2D;
    blend    := Blend.ALPHA;
    flip_x   := false;
    flip_y   := false;
    layer    := 0;
    autosize := true;
    rect     := Rect.{};     @JsonIgnore @EditorReadOnly 
}

draw_sprite_entities :: () {
    view := get_entity_view(Transform2D_Component, Sprite_Component);
    entities: [..] Entity;
    
    for entity: view {
        array_add(*entities, entity ,,temp);
    }

    Sort.quick_sort(entities, e => get_component(Sprite_Component, e).layer);

    for entity: entities {
        using transform := get_component(Transform2D_Component, entity);
        using sprite    := get_component(Sprite_Component,      entity);
        
        if !visible then return;
        
        if has_component(Blink_Component, entity)
        then update_blink(get_component(Blink_Component, entity), *tint);

        flags: QuadFlag;
        
        if autosize        then flags |= .AUTOSIZE;
        if flip_x          then flags |= .FLIP_X;
        if flip_y          then flags |= .FLIP_Y;

        sprite_quad := Quad.{
            transform = get_matrix(entity), 
            blend     = blend, 
            tint      = tint, 
            size      = size, 
            image     = image, 
            pixel_id  = xx entity, 
            flags     = flags
        };

        draw_quad(sprite_quad);
    }
}