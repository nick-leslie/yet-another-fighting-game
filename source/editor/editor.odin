package editor

import gk "../game_kernel"
import chars "../characters"
import rl "vendor:raylib"

//todo goals
// allow for users to edit hit and hurt boxes.
// allow for users to draw new hit and hurt boxes
// allow for users to see frames of animations

EditorState :: struct {
    charecter:gk.CharecterBase(chars.Charecter),
}

// used to run stand alone
main :: proc() {
editor_state := EditorState{}
 for rl.WindowShouldClose() {
     draw_editor(editor_state)
 }
}

draw_editor :: proc(editor_state:EditorState) {
    rl.BeginDrawing()

    rl.EndDrawing()
}

update_editor :: proc() {

}
