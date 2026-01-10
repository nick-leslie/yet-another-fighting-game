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

import "core:fmt"
import "core:log"
import "base:runtime"
// import "core:fmt"
// import "core:math/linalg"
import rl "vendor:raylib"
import gk "game_kernel"
// import "vendor:raylib/rlgl"
import clay "../libs/clay-odin"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	run:            bool,
	world: 		    gk.World,
	p1_controls: 	Controls,
	p2_controls: 	Controls,
	model_tmp: 		rl.Model,
	clay_arena:     clay.Arena,
}

CAMERA_DISTANCE :: 60
CAMERA_POSITION :: Vec3{0, 10, CAMERA_DISTANCE}
CAMERA_TARGET   :: Vec3 {0,25,0}
Vec3 :: [3]f32
Vec2 :: [2]f32
Vec4 :: [4]f32

Quat :: quaternion128

FLOOR_POSITION: Vec3 = {0, 0, 0}
QUAT_IDENTITY: Quat = 1
VEC3_ZERO: Vec3 = 0
UP :: Vec3{0, 1, 0}
FLOOR_EXTENT: Vec3={150, 0.05, 10}


g: ^Game_Memory

g_context: runtime.Context

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
	input := poll_charecter_input(g.p1_controls,true)
	gk.world_tic(&g.world,input)
	//tood check hits
}

physics_update :: proc() {
	gk.world_physics_tic(&g.world)
}


draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode3D(game_camera())

	charecter_draw(g.world.p1)
	charecter_draw(g.world.p2)
	charecter_draw_hit_boxes(g.world.p1)
	charecter_draw_hit_boxes(g.world.p2)
	rl.DrawCube(FLOOR_POSITION, 100, 1, 1, rl.WHITE)
	rl.DrawModel(g.model_tmp,{0,0,0},1,rl.WHITE)

	rl.DrawCircle3D(CAMERA_TARGET,1,{},0,rl.BLUE)

	rl.EndMode3D()
	rl.BeginMode2D(ui_camera())
	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("p1_pos: %v",   g.world.p1.position), 5, 5, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p1_velocity: %v",   g.world.p1.velocity), 5, 30, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p1_state: %d", g.world.p1.current_state), 5, 13, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p1_hitstun: %d", g.world.p1.hit_stun_frames), 5, 20, 8, rl.WHITE)
	rl.DrawFPS(5, 50)
	rl.DrawText(fmt.ctprintf("Combo Counter: %d", g.world.combo_counter), 5, 90, 8, rl.WHITE)

	rl.DrawText(fmt.ctprintf("p2_pos: %v", g.world.p2.position), 170, 5, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p2_pos: %v", g.world.p2.velocity), 250, 5, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p2_state: %d", g.world.p2.current_state), 170, 12, 8, rl.WHITE)
	rl.DrawText(fmt.ctprintf("p2_hitstun: %d", g.world.p2.hit_stun_frames), 170, 20, 8, rl.WHITE)


	rl.EndMode2D()

	rl.EndDrawing()
}


@(export)
game_update :: proc() {
	update()
	physics_update()
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	// rl.ToggleFullscreen()
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
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
		position = {0, 10, 0},
		move_speed = 20,
		air_drag = 0.5,
		air_move_speed = 15,
		jump_height = 50,
		p1_side = true,
		input_buffer = {},
	}
	p2 := gk.CharecterBase {
		health=100,
		position = {10, 10, 0},
		move_speed = 50,
		air_drag = 0.5,
		air_move_speed = 10,
		jump_height = 20,
		p1_side = false,
		input_buffer = {},
	}
	gk.initilize_charecter_memory(&p1)
	gk.initilize_charecter_memory(&p2)
	add_state_movement(&p1) // the nill is tmp
	add_state_light_attack(&p1)
	add_state_stun(&p1)
	add_state_movement(&p2) // the nill is tmp
	add_state_stun(&p2)
	log.debug(p1.states[:])
	clay_arena := initalise_memory({1280, 720})
	g^ = Game_Memory {
		run = true,
		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		clay_arena=clay_arena,
		world=	gk.world_init(p1,p2),
		p1_controls=p1_controls,
		model_tmp=rl.LoadModel("assets/tmp/psx_humanoid_female.glb"),
	}
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
	free(g)

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
