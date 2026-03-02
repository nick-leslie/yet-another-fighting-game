/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:sync"
// import "core:fmt"
import "core:log"
import "base:runtime"
// import "core:fmt"
// import "core:math/linalg"
import rl "vendor:raylib"
import gk "game_kernel"
// import "vendor:raylib/rlgl"
import clay "../libs/clay-odin"
import "core:prof/spall"
import psy "./physics"

PIXEL_WINDOW_HEIGHT :: 180
MAX_ROLLBACK_WINDOW :: 15
Game_Memory :: struct {
	run:            bool,
	world: 		    gk.World,
	p1_controls: 	Controls,
	p2_controls: 	Controls,
	model_tmp: 		rl.Model,
	clay_arena:     clay.Arena,
	cam: 			rl.Camera3D,
	rollback_state: RollbackStateQueue,
	// setup game arena
	fonts: 			[dynamic]Raylib_Font,
}

CAMERA_DISTANCE :: 60
CAMERA_POSITION :: Vec3{0, 10, CAMERA_DISTANCE}
CAMERA_TARGET   :: Vec3 {0,25,0}
Vec3 :: [3]f32
Vec364 :: [3]f64
Vec2 :: [2]f32
Vec264 :: [2]f64
Vec4 :: [4]f32

Quat :: quaternion128

FLOOR_POSITION: Vec3 = {0, 0, 0}
QUAT_IDENTITY: Quat = 1
VEC3_ZERO: Vec3 = 0
UP :: Vec3{0, 1, 0}
FLOOR_EXTENT: Vec3={150, 0.05, 10}
debugModeEnabled := false

g: ^Game_Memory

g_context: runtime.Context

default_font:rl.Font

game_camera :: proc() ->rl.Camera3D {

	return rl.Camera3D {
		position   = CAMERA_POSITION,
		target     = CAMERA_TARGET, // target 0,0
		up         = UP,
		fovy       = 60.0,
		projection = rl.CameraProjection.PERSPECTIVE,
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

// all of this needs to go in world
update :: proc() {
	//move me out
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
	p1_input := poll_charecter_input(g.p1_controls,true)
	p2_input := gk.Input {
		dir = gk.Direction.Neutral,
	}
	gk.world_tic(&g.world,p1_input,p2_input)
	//tood check hits
}

physics_update :: proc() {
	gk.world_physics_tic(&g.world)
}

free_cam := false

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	if rl.IsKeyPressed(.F) {
		free_cam = !free_cam
	}
	if free_cam {
		rl.UpdateCamera(&g.cam,.FREE)
	} else {
	}
	if rl.IsKeyPressed(.R) && free_cam == false{
		g.cam = game_camera() // we may want to only do this once but tmp for now
	}
	rl.BeginMode3D(g.cam)

	charecter_draw(g.world.p1)
	charecter_draw(g.world.p2)
	charecter_draw_hit_boxes(g.world.p1)
	charecter_draw_hit_boxes(g.world.p2)
	rl.DrawCube(FLOOR_POSITION, 100, 1, 1, rl.WHITE)
	// rl.DrawModelEx(g.model_tmp,{0,0,0},{-1,0,0},90,500,rl.WHITE)

	rl.DrawCircle3D(CAMERA_TARGET,1,{},0,rl.BLUE)

	rl.EndMode3D()

	clay.SetPointerState(rl.GetMousePosition(), rl.IsMouseButtonDown(rl.MouseButton.LEFT))
    clay.UpdateScrollContainers(false, rl.GetMouseWheelMoveV(), rl.GetFrameTime())
    clay.SetLayoutDimensions({cast(f32)rl.GetRenderWidth(), cast(f32)rl.GetRenderHeight() })
	if (rl.IsKeyPressed(.C)) {
        debugModeEnabled = !debugModeEnabled
        clay.SetDebugModeEnabled(debugModeEnabled)
    }
	commands := create_ui_layout()

	//something is going wrong with the interactions between the cam and clay
	clay_raylib_render(&commands,g.fonts,context.temp_allocator)
	// rl.DrawFPS(5, 50)

	rl.EndDrawing()
}

// last_world_state:gk.SerlizedWorld
//




@(export)
game_update :: proc() {
    if rl.IsKeyPressed(.ESCAPE) {
  		g.run = false
   	}
    if g.run == false {
        return
    }
    // log.debug("---------------------------")
    // todo go back 7 and resimulate in debug zzzz
    // log.debug(g.rollback_state.current_index)
    // log.debug(g.rollback_state.current_frame)

    if ODIN_DEBUG == true {
        debug_rollback(&g.rollback_state,DEBUG_ROLLBACK_FRAMES)
    }

    // last_world_state := get_current_state(&g.rollback_state)
    // log.debug(g.rollback_state.current_index)
    // gk.deserlize_world(last_world_state.world_state,&g.world)

   	p1_input := poll_charecter_input(g.p1_controls,true)
   	p2_input := gk.Input {
  		dir = gk.Direction.Neutral,
   	}
   	gk.world_tic(&g.world,p1_input,p2_input)
   	gk.world_physics_tic(&g.world)
   	add_new_state(&g.rollback_state,g.world,[2]gk.Input{p1_input,p2_input})
    // log.debug(g.rollback_state.current_frame)
    // log.debug(g.rollback_state.current_index)

	//
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	// rl.ToggleFullscreen()
	// rl.SetWwaindowPosition(200, 200)
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	spall_ctx = spall.context_create("profile.spall")  // Creates the .spall file

    buffer_backing = make([]u8, spall.BUFFER_DEFAULT_SIZE)
    spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))


    default_font = rl.GetFontDefault()

	utf_font := rl.LoadFont("./assets/nishiki-teki-font/NishikiTeki-MVxaJ.ttf")
	g_context = context
	g = new(Game_Memory)
	//TODO investigate why we cant move you below the setup of G
	p1_controls := Keyboard {
		up_key = rl.KeyboardKey.W,
		down_key = rl.KeyboardKey.S,
		left_key = rl.KeyboardKey.A,
		right_key = rl.KeyboardKey.D,
		light_key = rl.KeyboardKey.J,
		medium_key = rl.KeyboardKey.K,
		heavy_key = rl.KeyboardKey.L,
	}

	p1 := gk.CharecterBase {
		health=100,
		body = psy.body_init({0, 10}),
		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2}),
		move_speed = 7,
		air_drag = 0.5,
		air_move_speed = 15,
		jump_height = 50,
		p1_side = true,
	}
	p2 := gk.CharecterBase {
		health=100,
		body = psy.body_init({10, 10}),
		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2}),
		move_speed = 50,
		air_drag = 0.5,
		air_move_speed = 10,
		jump_height = 20,
		p1_side = false,
	}
	gk.initilize_charecter_memory(&p1)
	log.debug(p1.entity_pool)
	gk.initilize_charecter_memory(&p2)
	//we need this to be in a predictable order factory time
	add_state_movement(&p1) // the nill is tmp
	add_state_light_attack(&p1)
	add_state_light_fireball(&p1)
	log.debug(p1.entity_pool)
	add_state_stun(&p1)
	add_state_movement(&p2) // the nill is tmp
	add_state_stun(&p2)
	clay_arena := setup_clay({
		1280,
		720,
	})
	fonts := make([dynamic]Raylib_Font)
	append(&fonts,Raylib_Font{
	  fontId=0,
	  font=default_font,
	})
	append(&fonts,Raylib_Font{
		  fontId=0,
		  font=utf_font,
	})
	g^ = Game_Memory {
		run = true,
		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		clay_arena=clay_arena,
		world=	gk.world_init(p1,p2),
		p1_controls=p1_controls,
		// model_tmp=rl.LoadModel("assets/tmp/test.glb"),
		cam = game_camera(),
		fonts = fonts,
	}
	// last_world_state=gk.serlize_world(g.world)
	// setup the inital world state
	g.rollback_state = create_new_rollback_queue()
	game_hot_reloaded(g)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}


@(export)
game_shutdown :: proc() {
	// delete_charecter(&g.p1)
	// delete_charecter(&g.p2)
	gk.destroy_world(g.world) // we may want to pass world
	rl.UnloadModel(g.model_tmp)
	free(g.clay_arena.memory) // we may want to put this in its own arena
	delete(g.fonts)
	free_rollback_state_queue(&g.rollback_state)
	free(g)
	//destroy spall
 	spall.context_destroy(&spall_ctx)             // Flushes and closes file
    delete(buffer_backing)
    spall.buffer_destroy(&spall_ctx, &spall_buffer)  // Writes buffer to file

}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)
	g_context = context
	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}



spall_ctx: spall.Context
buffer_backing: []u8
@(thread_local) spall_buffer: spall.Buffer  // thread_local if using multiple threads

@(instrumentation_enter)
spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
}


@(instrumentation_exit)
spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
	spall._buffer_end(&spall_ctx, &spall_buffer)
}
