package editor


import "core:log"
import gk "../game_kernel"
import chars "../characters"
import rl "vendor:raylib"
import render "../rendering"
import clay "../../libs/clay-odin"
import psy "../physics"
import vmem "core:mem/virtual"
//todo goals
// allow for users to edit hit and hurt boxes.
// allow for users to draw new hit and hurt boxes
// allow for users to see frames of animations


EditorState :: struct {
    charecter:gk.CharecterBase(chars.Charecter),
    fonts:     [dynamic]render.Raylib_Font,
    clay_arena:     clay.Arena,
    arena: vmem.Arena,
    //store currently selected hit box
    // also we should figure out file format
}

setup_editor :: proc(charecter:gk.CharecterBase(chars.Charecter)) -> EditorState {
    e := EditorState{
        charecter=charecter,
    }
   	clay_arena := render.setup_clay({
		1920,
		1080,
	})
    arena_alocator := vmem.arena_allocator(&e.arena)
    fonts := make([dynamic]render.Raylib_Font,arena_alocator)
    e.fonts = fonts
    e.clay_arena = clay_arena
    render.set_fonts(&e.fonts)
    return e
}

make_editor_window :: proc() {
    rl.InitWindow(1920, 1080, "Editor")
    rl.SetTargetFPS(60)
}

clean_up_editor :: proc(editor_state:^EditorState) {
    vmem.arena_destroy(&editor_state.arena)
   	free(editor_state.clay_arena.memory) // we may want to put this in its own arena

}

// used to run stand alone
main :: proc() {
   	context.logger = log.create_console_logger()
    make_editor_window()
    defer rl.CloseWindow()


    editor_state := setup_editor(chars.create_cyberpunk_charecter({0,0,2,0},200))
    set_charecter_state_by_name(&editor_state, "neutral")
    for rl.WindowShouldClose()==false {
        draw_editor(editor_state)
        update_editor()
    }

    clean_up_editor(&editor_state)
    // todo setup a close
}

editor_camera :: proc() ->rl.Camera3D {
    //todo fix me
	return rl.Camera3D {
		position   = {0,0,-20},
		target     = {}, // target 0,0
		up         = render.UP,
		fovy       = 60.0,
		projection = rl.CameraProjection.ORTHOGRAPHIC,
	}
}
PIXEL_WINDOW_HEIGHT :: 180
ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT}
}

set_charecter_state_by_name :: proc(editor_state:^EditorState,name:string) {
    for state,i in editor_state.charecter.states {
        if state.name == name {
            editor_state.charecter.serlized_state.current_state = gk.state_index(i)
            return
        }
    }
    assert(false, "state not found:")
}

draw_editor :: proc(editor_state: EditorState) {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
    char_body := psy.unfix_body_32(editor_state.charecter.body)
    cam := editor_camera()
    rl.BeginMode3D(cam)
    render.charecter_draw(editor_state.charecter, false)
    rl.EndMode3D()

    // Screen space — no BeginMode2D, so border width 1 == 1 actual pixel
    zoom := f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT

    clay.BeginLayout()
    state, frame := gk.charecter_get_current_state_frame(editor_state.charecter)
    for &hurt_box_index in frame.hurtbox_list {
        draw_hurt_boxe_clay(char_body.position, state.moveboxs[hurt_box_index].(gk.Hurt_box), cam)    }
    commands := clay.EndLayout()
    render.clay_raylib_render(&commands)

    rl.EndDrawing()
}

@(private = "file")
anchor_point :: proc() {
    if clay.UI()({
        layout = {sizing = {clay.SizingFixed(10), clay.SizingFixed(10)}},
        backgroundColor = render.rl_to_clay_color(rl.WHITE),
    }) {}
}



@(private = "file")
anchor_row :: proc(grow_height: bool) {
    if clay.UI()({
        layout = {
            sizing = {
                width  = clay.SizingGrow({}),
                height = grow_height ? clay.SizingGrow({}) : clay.SizingFit({}),
            },
            childAlignment = {y = .Center},
        },
    }) {
        anchor_point()
        if clay.UI()({layout = {sizing = {width = clay.SizingGrow({})}}}) {}
        anchor_point()
        if clay.UI()({layout = {sizing = {width = clay.SizingGrow({})}}}) {}
        anchor_point()
    }
}

draw_hurt_boxe_clay :: proc(offset: [2]f32, hurt_box: gk.Hurt_box, cam: rl.Camera3D) {
    unfixed_box := psy.unfix_box_32(hurt_box)

    world_center := offset + unfixed_box.position
    screen_center := rl.GetWorldToScreen({world_center.x, world_center.y, 0}, cam)

    // ortho: fovy = visible world height
    px_per_unit := f32(rl.GetScreenHeight()) / cam.fovy

    if clay.UI()({
        floating = {
            offset     = {screen_center.x, screen_center.y},
            attachment = {element = .CenterCenter},
            attachTo   = .Root,
        },
        layout = {
            layoutDirection = .TopToBottom,   // <- replaces childAlignment
            sizing = {
                width  = clay.SizingFixed(unfixed_box.extent.x * px_per_unit),
                height = clay.SizingFixed(unfixed_box.extent.y * px_per_unit),
            },
        },
        border = {
            color = render.rl_to_clay_color(rl.RED),
            width = {1, 1, 1, 1, 0},
        },
        backgroundColor = render.rl_to_clay_color(rl.Fade(rl.BLUE, 0.50)),
    }) {
        anchor_row(false) // top:    corners + top-center
        anchor_row(true)  // middle: left-center, center, right-center
        anchor_row(false) // bottom: corners + bottom-center
    }
}
debugModeEnabled := false
update_editor :: proc() {
    clay.SetPointerState(rl.GetMousePosition(), rl.IsMouseButtonDown(rl.MouseButton.LEFT))
    clay.UpdateScrollContainers(false, rl.GetMouseWheelMoveV(), rl.GetFrameTime())
    clay.SetLayoutDimensions({cast(f32)rl.GetRenderWidth(), cast(f32)rl.GetRenderHeight() })
    if (rl.IsKeyPressed(.C)) {
        debugModeEnabled = !debugModeEnabled
        clay.SetDebugModeEnabled(debugModeEnabled)
    }
}
