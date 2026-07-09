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
    frame:int,
    state:int,
}

// used to run stand alone
main :: proc() {
 for rl.WindowShouldClose() {
     draw_editor()
 }
}

draw_editor :: proc() {
    rl.BeginDrawing()
    rl.EndDrawing()
}

update_editor :: proc() {

}
