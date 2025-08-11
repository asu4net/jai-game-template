
ON_END_CBK :: #type (Entity);

Timer_Component :: struct @Component @InitOrder(1000)  {
    started      : bool = false;
    time         : f32;
    current_time : f32  = 0; @JsonIgnore
    on_end_cbk   : ON_END_CBK; @JsonIgnore @EditorIgnore
}

// not init
start_timer_component :: (entity : Entity, finished_cbk : ON_END_CBK) {
    using timer := get_component(Timer_Component, entity);
    started               = true;
    current_time          = 0;
    on_end_cbk = finished_cbk;
}

tick_timer_entities :: () {
    view := get_entity_view(Timer_Component);
    for entity: view {
        using timer  := get_component(Timer_Component, entity);

        if (!started) { return; }

        current_time += frame_time();
        if (current_time > time) {
            started = false;
            on_end_cbk(entity);
        }
    }
}