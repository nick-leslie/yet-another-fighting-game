package editor

import "base:runtime"

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
    clay_context: ^clay.Context,
    show_moves_dropdown:bool,
    selected_box: ^gk.MoveBox
    //store currently selected hit box
    // also we should figure out file format
}

setup_editor :: proc(charecter:gk.CharecterBase(chars.Charecter)) -> EditorState {
    e := EditorState{
        charecter=charecter,
    }
   	clay_arena,ctx := render.setup_clay({
		1920,
		1080,
	})
    arena_alocator := vmem.arena_allocator(&e.arena)
    fonts := make([dynamic]render.Raylib_Font,arena_alocator)
   	append(&fonts,render.Raylib_Font{
	  fontId=0,
	  font=rl.GetFontDefault(),
	})
    e.fonts = fonts
    e.clay_context = ctx
    e.clay_arena = clay_arena
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

editor:^EditorState
g_context:runtime.Context
// used to run stand alone
main :: proc() {
   	context.logger = log.create_console_logger()
    g_context = context
    make_editor_window()
    defer rl.CloseWindow()


    editor = new(EditorState)
    editor^ = setup_editor(chars.create_cyberpunk_charecter({0,0,2,0},200))
    render.set_fonts(&editor.fonts)
    set_charecter_state_by_name(editor, "neutral")
    clay.SetCurrentContext(editor.clay_context)
    for rl.WindowShouldClose()==false {
        draw_editor(editor)
        update_editor(editor)
    }

    clean_up_editor(editor)
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

debugModeEnabled := false
update_editor :: proc(editor_state: ^EditorState) {
    left_mouse_state := rl.IsMouseButtonDown(rl.MouseButton.LEFT)
    clay.SetPointerState(rl.GetMousePosition(), left_mouse_state)
    clay.UpdateScrollContainers(false, rl.GetMouseWheelMoveV(), rl.GetFrameTime())
    clay.SetLayoutDimensions({cast(f32)rl.GetRenderWidth(), cast(f32)rl.GetRenderHeight() })
    if (rl.IsKeyPressed(.C)) {
        debugModeEnabled = !debugModeEnabled
        clay.SetDebugModeEnabled(debugModeEnabled)
    }

    ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), editor_camera())
    if editor_state.selected_box != nil {
        //todo dont snap the box pos directly to the mouse
        mouse_to_char := psy.sub_fixed_vec2(editor_state.charecter.serlized_state.body.position,psy.fix_vector_32([2]f32{-ray.position.x,-ray.position.y}))
            switch &v in editor_state.selected_box {
                case gk.Hit_box:
                    if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && psy.check_box_point_collision(v,mouse_to_char) {
                        v.box.position = mouse_to_char
                    }
                case gk.Hurt_box:
                    if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && psy.check_box_point_collision(v,mouse_to_char) {
                        v.box.position = mouse_to_char
                    }
            }
        }
        if left_mouse_state == false {
    }
}


draw_editor :: proc(editor_state: ^EditorState) {
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
    _, frame := gk.charecter_get_current_state_frame(editor_state.charecter)
    state_index := editor_state.charecter.serlized_state.current_state
    state_drop_down(editor_state)
    if len(editor_state.charecter.states[state_index].moveboxs) > 0 {
        for &hurt_box_index in frame.hurtbox_list {
            draw_hurt_box_clay(char_body.position, &editor_state.charecter.states[state_index].moveboxs[hurt_box_index], cam)
        }  
    }
    commands := clay.EndLayout()
    render.clay_raylib_render(&commands)

    rl.EndDrawing()
}

state_drop_down :: proc(editor_state: ^EditorState) {
    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = {
                width  = clay.SizingFit(),
                height = clay.SizingFit(),
            },
            padding = {10,10,10,10},
        },
        border = {
            color = render.rl_to_clay_color(rl.GRAY),
            width = {1, 1, 1, 1, 0},
        },
    })
    {
        state, frame := gk.charecter_get_current_state_frame(editor_state.charecter)
        clay.TextDynamic(state.name,clay.TextConfig({fontSize=40,letterSpacing=2,fontId=0,textColor={255,255,255,255},textAlignment=.Left}))
        clay.OnHover(proc "c" (id: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
            editor_state := (^EditorState)(userData)
            if pointerData.state == .Pressed {
                editor_state.show_moves_dropdown = true
            } else if pointerData.state == .Released {
                editor_state.show_moves_dropdown = false
            }
        }, editor_state)
    }

    if editor_state.show_moves_dropdown {
        clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width  = clay.SizingFit(),
                    height = clay.SizingFit(),
                },
                padding = {10,10,10,10},
            },
            border = {
                color = render.rl_to_clay_color(rl.GRAY),
                width = {1, 1, 1, 1, 0},
            },
        })
        {
            for states,state_index in editor_state.charecter.states {
                if clay.UI()({
                    backgroundColor = render.rl_to_clay_color(rl.GRAY) if clay.Hovered() else render.rl_to_clay_color(rl.BLACK),
                }) {
                    clay.TextDynamic(states.name, clay.TextConfig({fontSize=20,letterSpacing=1,fontId=0,textColor={255,255,255,255},textAlignment=.Left}))
                    clay.OnHover(proc "c" (id: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
                        if pointerData.state == .ReleasedThisFrame {
                            editor.charecter.serlized_state.current_state = gk.state_index(uintptr(userData))
                        }
                    },rawptr(uintptr(state_index)))
                }
            }
        }
    }
}

anchor_point :: proc() {
    if clay.UI()({
        layout = {sizing = {clay.SizingFixed(10), clay.SizingFixed(10)}},
        backgroundColor = render.rl_to_clay_color(rl.WHITE),
    }) {}
}

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

draw_hurt_box_clay :: proc(charecter_offset: [2]f32, hurt_box: ^gk.MoveBox, cam: rl.Camera3D) {
    unfixed_box := psy.unfix_box_32(hurt_box.(gk.Hurt_box))

    world_center := charecter_offset + unfixed_box.position
    screen_center := rl.GetWorldToScreen({world_center.x, world_center.y, 0}, cam)

    // ortho: fovy = visible world height
    px_per_unit := f32(rl.GetScreenHeight()) / cam.fovy

    if clay.UI(clay.ID_LOCAL("hurt box"))({
        floating = {
            offset     = {screen_center.x, screen_center.y},
            attachment = {element = .CenterCenter},
            attachTo   = .Root,
        },
        layout = {
            layoutDirection = .TopToBottom,
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
        clay.OnHover(proc "c" (id: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
            context = g_context
            box := (^gk.MoveBox)(userData)
            if pointerData.state == .PressedThisFrame {
                editor.selected_box = box
            }
        },hurt_box)
    }
}
