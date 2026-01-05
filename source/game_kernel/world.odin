package game_kernel

import "core:log"
import "../../libs/jolt"
import "base:runtime"


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
FLOOR_EXTENT: Vec3={100, 0.05, 10}



Stage :: struct {
	floor_id:   jolt.BodyID,
	left_wall:  jolt.BodyID,
	right_wall: jolt.BodyID,
	// todo add wall
}


World :: struct {
	physicsManager: Physics_Manager,
	stage:          Stage,
	p1:             CharecterBase, // these should be charecters
	p2:             CharecterBase,
}


g_context: runtime.Context

world_init :: proc(p1:CharecterBase,p2:CharecterBase) -> World {
	g_context = context
	p1 := p1 //todo figure out this
	p2 := p2
	pm := create_physics_mannager()
	floor_id := add_floor(&pm)
	world := World{}
	for &state in p1.states {
		setup_move_bodys(&state,pm)
	}
	for &state in p2.states {
		setup_move_bodys(&state,pm)
	}
	world.p1=p1
	world.p2=p2
	world.stage= {
		floor_id=floor_id,
	}
	world.physicsManager=pm
	setup_charecter(&world.p1, &pm)
	setup_charecter(&world.p2, &pm)
	return world
}

destroy_world :: proc(w:World) {
	w:=w
	delete_charecter(&w.p1) // we may want to
	delete_charecter(&w.p2) // we may want to
}


FIXED_STEP: f32 = 1.0 / 60.0 // do we need this here or should we put this in the update

world_tic ::proc(w:^World,p1_input:Input) {
	log.debug("starting p1 update")
	charecter_update(&w.p1, p1_input)

	//todo take me as an input
	p2_input := Input {
		dir = Direction.DownBack,
	} // todo move this out for rollback
	charecter_update(&w.p2, p2_input)

	log.debug("starting to add hurt boxes")
	character_add_hurt_boxes(w.p1, w.physicsManager) // investigate why comenting this out breaks things
	character_add_hurt_boxes(w.p2, w.physicsManager)
	character_check_hit(&{&w.p1, &w.p2}, w)
}


world_physics_tic ::proc(w:^World) {
	//move me out
	log.debug("charecter physics update 1")
	charecter_physics_update(&w.p1, w)
	log.debug("charecter physics update 2")
	charecter_physics_update(&w.p2, w)
	log.debug("jolt physics update 2")
	// update normal physics
	jolt.PhysicsSystem_Update(
		w.physicsManager.physicsSystem,
		FIXED_STEP,
		1,
		w.physicsManager.jobSystem,
	)
}
