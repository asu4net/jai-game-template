Editor :: struct {
    show_demo                : bool;
    show_hierarchy           : bool = true;
    selected_ref             : Entity_Ref;
}

#add_context editor : Editor;

draw_editor :: () {
    using context.editor;
    
    if ImGui.BeginMenuBar()  {
        if ImGui.BeginMenu("ImGui") {
            ImGui.Checkbox("Show demo", *show_demo);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Entity")  {
            ImGui.Checkbox("Show hierarchy",  *show_hierarchy);
            if ImGui.MenuItem("New") {
                entity := create_entity();
                context.editor.selected_ref = make_ref(entity);
            }
            if ImGui.BeginMenu("Load") {
                // Load all the prefabs
                File_Utils.visit_files("assets/entities", true, null, (info: *File_Utils.File_Visit_Info, *void) {
                    path, basename, ext := path_decomp(info.full_name ,,temp);
                    if ext != "json" {
                        return;
                    }
                    if ImGui.MenuItem(to_c_string(basename ,,temp)) {
                        entity := dlz_entity_from_file(info.full_name, autopath = false);
                        assert(entity != NULL_ENTITY);
                        context.editor.selected_ref = make_ref(entity);
                        context.editor.show_hierarchy = true;
                    }
                });
                ImGui.EndMenu();
            }
            selected := resolve_ref(*context.editor.selected_ref);
            if selected != NULL_ENTITY && ImGui.MenuItem("Save") {
                save_selected();
            }
            if selected != NULL_ENTITY && ImGui.MenuItem("Destroy") {
                destroy_selected();
            }
            ImGui.EndMenu();
        }
        ImGui.EndMenuBar();
    }

    if show_demo {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_demo);
    }

    if show_hierarchy {
        draw_all_entities_hierarchy(*show_hierarchy);
        draw_properties(*show_hierarchy);
    }
}

save_selected :: () {
    using context.editor;
    entity := resolve_ref(*selected_ref);
    assert(entity != NULL_ENTITY);
    builder: String_Builder;
    slz_entity(*builder, entity ,,temp);
    text := builder_to_string(*builder ,,temp);
    src  := tprint("assets/entities/%.json", get_name(entity) ,,temp);
    File.write_entire_file(src, text);
}

destroy_selected :: () {
    using context.editor;
    entity := resolve_ref(*selected_ref);
    assert(entity != NULL_ENTITY);
    destroy_entity(entity);
    context.editor.selected_ref = .{};
}