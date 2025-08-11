#load "engine/core.jai";
#load "engine/graphics.jai";

#if ECS    #load "engine/ecs.jai";
#if EDITOR #load "engine/editor.jai";

#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import "Hash_Table";

System     :: #import "System";
File       :: #import "File";
File_Utils :: #import "File_Utilities";
String     :: #import "String";

Jaison :: #import "Jaison";