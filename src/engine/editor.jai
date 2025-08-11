#load "editor/utils.jai";

#if IMGUI {
    #load "editor/editor_props.jai";

    #if ECS {
        #load "editor/editor_state.jai";
        #load "editor/panels/properties.jai";
        #load "editor/panels/hierarchy.jai";
    }
}