is_input_action_down :: (s: Input_Action) -> bool {
    pressed : bool;
    keys := INPUT_ACTION_MAP[s];
    for keys {
        if !is_key_down(it)
        then return false;
    }
    return true;
}

update_input_actions :: () {
    for i : 0..Input_Action.COUNT - 1 {
        input_actions_down[i] = is_input_action_down(xx i);
    }

    for i : 0..Input_Action.COUNT - 1 {
        input_actions_pressed[i] = input_actions_down[i] && !input_actions_prev[i];
    }

    memcpy(*input_actions_prev, *input_actions_down, Input_Action.COUNT.(s64) * size_of(bool));
}

is_input_action_pressed :: inline (s: Input_Action) -> bool {
    return input_actions_pressed[s];
}

#insert #run generate_comp_time_input_map();

#scope_file

#import "Enum_Array";

input_actions_prev    : [Input_Action.COUNT] bool;
input_actions_down    : [Input_Action.COUNT] bool;
input_actions_pressed : [Input_Action.COUNT] bool;

// Example

// Input_Action :: enum {
//     TOGGLE_PLAY; TOGGLE_PAUSE; NEXT_FRAME; TOGGLE_SHOW_COLLIDERS;
//     COUNT;
// }

// INPUT_ACTION_MAP :: Enumerated_Array(Input_Action, [] Keycode).{values=.{
//   TOGGLE_PLAY            = .[.LALT, ._1],
//   TOGGLE_PAUSE           = .[.LALT, ._2],
//   NEXT_FRAME             = .[.LALT, ._3],
//   TOGGLE_SHOW_COLLIDERS  = .[.LALT, ._4],
// }};

INPUT_MAP_CODE :: #string SCOPE
Input_Action :: enum {
%
    COUNT;
}

INPUT_ACTION_MAP :: Enumerated_Array(Input_Action, [] Keycode).{values=.{
%
}};
SCOPE

INPUT_ENUM_ELEM :: #string SCOPE
    %;
SCOPE

INPUT_ENTRY_CODE :: #string SCOPE
    % = .[%]
SCOPE

generate_comp_time_input_map :: () -> string {
    #import "Compiler";

    default_code :: inline () -> string {
        return sprint(INPUT_MAP_CODE, "", "", "");
    }
    
    cwd := get_working_directory();

    ASSETS_DIR :: "bin/assets";

    assets_dir_created := File.make_directory_if_it_does_not_exist(ASSETS_DIR, recursive = true);
    if !assets_dir_created {
        log_error("Failed to create atlas. Couldn't setup the binaries dir. [%]", ASSETS_DIR);
        return default_code();
    } 

    set_working_directory("bin");
    defer set_working_directory(cwd);
    
    INPUT_ACTION_MAP_SRC :: "input_action_map.txt";

    log("Looking for input action map in [%]", INPUT_ACTION_MAP_SRC);
    if File_Utils.file_exists(INPUT_ACTION_MAP_SRC) {
        log("Input action map found.");
        map_str := File.read_entire_file(INPUT_ACTION_MAP_SRC);
        return default_code();    
    }
    
    log("Input action map not found.");
    return default_code();
}