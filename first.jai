#load "src/engine.jai";

main :: () {
    run_app(name = "Game?", width = 1920, height = 1080);
    defer end_app();

    while keep_running() {
        defer end_frame();

        tick_app();
        draw_frame();
        
        #if IMGUI {
            draw_imgui(() {
                #if EDITOR {
                    draw_editor();
                }
            });
        }
    }
}