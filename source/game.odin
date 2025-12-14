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

import "../libs/jolt"
import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"
// import "vendor:raylib/rlgl"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	run:            bool,
	physicsManager: Physics_Manager,
	stage:          Stage,
	p1:             Charecter,
}

Stage :: struct {
	floor_id:   jolt.BodyID,
	left_wall:  jolt.BodyID,
	right_wall: jolt.BodyID,
	// todo add wall
}

CAMERA_DISTANCE :: 50

Vec3 :: [3]f32
Vec2 :: [2]f32
Vec4 :: [4]f32

Quat :: quaternion128

FLOOR_POSITION: Vec3 = {0, -10, 0}
QUAT_IDENTITY: Quat = 1
VEC3_ZERO: Vec3 = 0
UP :: Vec3{0, 1, 0}

FIXED_STEP: f32 = 1.0 / 60.0 // do we need this here or should we put this in the update


g: ^Game_Memory

game_camera :: proc() -> rl.Camera3D {
	look_target: Vec3 = {}
	return rl.Camera3D {
		position   = look_target + linalg.mul(QUAT_IDENTITY, Vec3{0, 0, CAMERA_DISTANCE}),
		target     = look_target, // target 0,0
		up         = UP,
		fovy       = 45.0,
		projection = rl.CameraProjection.PERSPECTIVE,
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

update :: proc() {
    charecter_update(&g.p1)
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}

}

physics_update :: proc() {
	charecter_physics_update(&g.p1)
	// update normal physics
	jolt.PhysicsSystem_Update(
		g.physicsManager.physicsSystem,
		FIXED_STEP,
		1,
		g.physicsManager.jobSystem,
	)
}


draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode3D(game_camera())
	// {
	// 	rlgl.PushMatrix()

	// 	rl.DrawCubeV(0, 1 * 2, rl.RED)
	// 	rlgl.PopMatrix()
	// }
	rl.DrawCapsule(
		g.p1.position,
		g.p1.position + UP * CHARACTER_CAPSULE_HALF_HEIGHT * 2,
		CHARACTER_CAPSULE_RADIUS,
		16,
		8,
		rl.ORANGE,
	)

	rl.DrawCube(FLOOR_POSITION, 100, 1, 1, rl.WHITE)


	rl.EndMode3D()
	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("player_pos: %v", g.p1.position), 5, 5, 8, rl.WHITE)

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
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)
	pm := create_physics_mannager()
	char := Charecter {
		position       = {0, 10, 0},
		move_speed     = 10,
		air_drag       = 0.5,
		air_move_speed = 5,
		jump_height = 20,
		p1_side=true,
		input_buffer={},
		controls= Keyboard{
		    up_key=rl.KeyboardKey.W,
		    down_key=rl.KeyboardKey.S,
		    left_key=rl.KeyboardKey.A,
		    right_key=rl.KeyboardKey.D,
		},
	}
	//TODO investigate why we cant move you below the setup of G
	setup_charecter(&char, &pm)
	g^ = Game_Memory {
		run = true,
		physicsManager = pm,
		p1 = char,
		stage = {floor_id = add_floor(&pm)},
		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
	}
	add_state_movement(&g.p1)// the nill is tmp

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

add_floor :: proc(pm: ^Physics_Manager) -> jolt.BodyID {
	floor_extent := Vec3{100, 0.05, 10}
	floor_shape := jolt.BoxShape_Create(&floor_extent, 0)
	defer jolt.Shape_Destroy(auto_cast floor_shape)
	floor_settings := jolt.BodyCreationSettings_Create3(
		shape = auto_cast floor_shape,
		position = &FLOOR_POSITION,
		rotation = &QUAT_IDENTITY,
		motionType = .Static,
		objectLayer = PHYS_LAYER_NON_MOVING,
	)
	floor_body_id := jolt.BodyInterface_CreateAndAddBody(
		pm.bodyInterface,
		floor_settings,
		.Activate,
	)
	jolt.BodyCreationSettings_Destroy(floor_settings)
	return floor_body_id
}


@(export)
game_shutdown :: proc() {
    delete_charecter(&g.p1)
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
