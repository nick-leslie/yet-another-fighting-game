package game_kernel

import "core:log"
import "base:runtime"
import psy "../physics"


CAMERA_DISTANCE :: 60
CAMERA_POSITION :: Vec3{0, 10, CAMERA_DISTANCE}
CAMERA_TARGET   :: Vec3 {0,25,0}
Vec3 :: [3]f64
Vec2 :: [2]f64
Vec264 :: [2]f64
Vec4 :: [4]f32

Quat :: quaternion128

FLOOR_POSITION: Vec3 = {0, 0, 0}
QUAT_IDENTITY: Quat = 1
VEC3_ZERO: Vec3 = 0
UP :: Vec3{0, 1, 0}
FLOOR_EXTENT: Vec3={150, 0.05, 10}



Stage :: struct {
	floor:      psy.FixedBox,
	// todo add wall
}


World :: struct {
	// Physics_Manager should be global and percist between frames take these out
	stage:             Stage,

	// rollbackable
	p1:                CharecterBase, // these should be charecters
	p2:                CharecterBase,
	p1_input_buffer:   InputBuffer,
	p2_input_buffer:   InputBuffer,
	hit_stop:		u32,
	//todo we may need to make this go to the charecters
	combo_counter: 	   int, // this needs to check when the enemy recovers   trades will make this goto 2
}


g_context: runtime.Context

world_init :: proc(p1:CharecterBase,p2:CharecterBase) -> World {
	log.info("creating world")
	g_context = context
	p1 := p1 //todo figure out this
	p2 := p2
	world := World{}
	world.p1_input_buffer = {}
	world.p2_input_buffer = {}
	world.p1=p1
	world.p2=p2
	world.stage= Stage{}
	setup_charecter(&world.p1)
	setup_charecter(&world.p2)
	return world
}

destroy_world :: proc(w:World) {
	w:=w
	delete_charecter(&w.p1) // we may want to
	delete_charecter(&w.p2) // we may want to
}


FIXED_STEP: f32 = 1.0 / 60.0 // do we need this here or should we put this in the update

world_tic ::proc(w:^World,p1_input:Input,p2_input:Input) {
	update_input_buffer(&w.p1_input_buffer, p1_input)
	update_input_buffer(&w.p2_input_buffer, p2_input)

	if w.hit_stop > 0 {
		w.hit_stop -=1
		return // dont run world updates during hitstop but still collect input
	}

	charecter_update(&w.p1, w.p1_input_buffer,w)
	charecter_update(&w.p2, w.p2_input_buffer,w)

	character_check_hit(&{&w.p1, &w.p2},&{&w.p1_input_buffer,&w.p2_input_buffer}, w)
	character_check_hit(&{&w.p2, &w.p1},&{&w.p2_input_buffer,&w.p1_input_buffer}, w)
}


world_physics_tic ::proc(w:^World) {
	//move me out
	charecter_physics_update(&w.p1, w)
	charecter_physics_update(&w.p2, w)
	// update normal physics
}
