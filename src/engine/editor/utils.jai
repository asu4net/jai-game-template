can_update_this_frame :: inline () -> bool {
    #if EDITOR {
    update_frame_by_frame_mode();    
    return next_frame;
    } else {
        return true;
    }
}

frame_by_frame : bool;
next_frame     : bool;
show_colliders : bool;

update_frame_by_frame_mode :: () {
    
    if performed(.TOGGLE_PAUSE) {
        frame_by_frame =! frame_by_frame;
    }

    if !frame_by_frame {
        next_frame = true;
        return;
    }

    next_frame = performed(.NEXT_FRAME);   
}

//#REVIEW_asuarez More commands stuff (maybe this should be in utils or main)

should_update_game :: () -> bool {

    #if EDITOR {
        if performed(.TOGGLE_PLAY) {
            // if !is_game_init()
            // then init_game();
            // else deinit_game();
        }
    }

    //return is_game_init();
    return true;
}