package game

import "../libs/jolt"
import "core:log"
import rl "vendor:raylib"

State :: struct {
	frames:        [dynamic]Frame,
	hurtbox_bodys: [dynamic]^jolt.Body, // all these bodys are precreated or alocated but asleep
	animation_ptr: ^rl.ModelAnimation,
	model_ptr:     ^rl.Model,
}

delete_state :: proc(move: ^State) {
	for &frame in move.frames {
		delete(frame.hitbox_list)
		delete(frame.hurtbox_list)
		delete(frame.cancel_states)
	}
	delete(move.frames)
	delete(move.hurtbox_bodys)
}

check_cancel_options :: proc(char: ^Charecter, cancel_index: int) -> bool {
	log.debug("huhhhh")
	state := char.states[char.current_state]
	frame := state.frames[char.current_frame]
	if len(frame.cancel_states) == 0 {
		return true
	}
	for &cancel_option in frame.cancel_states {
		if cancel_option == cancel_index {
			return true
		}
	}
	return false
}

jump_state_cancel :: proc(char: ^Charecter, cancel_index: int) -> bool {
	//todo make it so we only cansle jump state when we land or do a
	// jump normal/special

	if char.in_air == false {
		return true
	}
	// assert(false,"not implmented")
	return false
}

free_cancel :: proc(char: ^Charecter, cancel_index: int) -> bool {
	return true
}
no_cancel :: proc(char: ^Charecter, cancel_index: int) -> bool {
	return false
}

Frame :: struct {
	frame_index:   int, // we may want to remove this
	frame_type:    FrameType,
	cancel_states: [dynamic]int,
	hurtbox_list:  [dynamic]Hurt_box, // width height extent will be static
	hitbox_list:   [dynamic]Hit_box,
	on_frame:      proc(_: ^Charecter),
	check_exit:    proc(_: ^Charecter, _: int) -> bool, // takes char pointer and proposed state
}

Hurt_box :: struct {
	using position: Vec2,
	extent:         Vec2, // width height extent will be static
	body:        ^jolt.Body, // all these bodys are precreated or alocated but asleep
	// todo properties
}
Hit_box :: struct {
	using position: Vec2,
	extent:         Vec2, // width height extent will be static
	// todo properties
}


FrameType :: enum {
	Startup,
	Active,
	Recovery,
}


//todo we may want to replace this with code gen
// man this sucks but we love it
setup_move_bodys :: proc(move: ^State) {
	move.hurtbox_bodys = make([dynamic]^jolt.Body)
	past_hurtboxes := make([dynamic]^Hurt_box)
	defer delete(past_hurtboxes)
	for &frame in move.frames {
		for &hurt_box in frame.hurtbox_list {
			if hurt_box.extent[0] == 0 || hurt_box.extent[1] == 0 {
				// too check if in debug mode and assert fail
				log.debug("we are faling")
				assert(ODIN_DEBUG == false, "Hurtboxes should never have a 0 width or height")
				continue
			}
			used_past := false
			for &past_hurtboxes in past_hurtboxes {
				if hurt_box.x == past_hurtboxes.x &&
				   hurt_box.y == past_hurtboxes.y &&
				   hurt_box.extent.x == past_hurtboxes.extent.x &&
				   hurt_box.extent.y == past_hurtboxes.extent.y { 	// we use a because its slot 3
					//should we just use a pointer no probs more error prone
					hurt_box.body: = past_hurtboxes.body:
					used_past = true
					break
				}
			}
			if used_past == true {
				continue // skip the rest of the loop
			}
			box := hurt_box
			log.debug("past use previous")
			box_shape := jolt.BoxShape_Create(&{box.extent.x, box.extent.y, 10}, 0)
			log.debug("created box shape")
			pos := Vec3{hurt_box.x, hurt_box.y, 0}
			box_settings := jolt.BodyCreationSettings_Create3(
				shape = auto_cast box_shape,
				position = &pos,
				rotation = &QUAT_IDENTITY,
				motionType = .Static, // check this
				objectLayer = PHYS_LAYER_HURT_BOX,
			)
			log.debug("created created body")

			box.body: = jolt.BodyInterface_CreateBody(
				g.physicsManager.bodyInterface,
				box_settings,
			)

			log.debug("added body")
			jolt.BodyCreationSettings_Destroy(box_settings)
			append(&move.hurtbox_bodys, box.body:)
			append(&past_hurtboxes, &hurt_box)
			jolt.Shape_Destroy(auto_cast box_shape)
		}
	}
}

// we need to have a pool of hit and hurt boxes that we resize every frame so that we can save state
scan_for_hits :: proc() {
	// NarrowPhaseQuery_CastShape2 :: proc(
	//     query: ^NarrowPhaseQuery,
	//     shape: ^Shape,
	//     worldTransform: ^RMat4,
	//     direction: ^Vec3,
	//     settings: ^ShapeCastSettings,
	//     baseOffset: ^RVec3,
	//     collectorType: CollisionCollectorType,
	//     callback: CastShapeResultCallback,
	//     userData: rawptr, // this should be context
	//     broadPhaseLayerFilter: ^BroadPhaseLayerFilter,
	//     objectLayerFilter: ^ObjectLayerFilter,
	//     bodyFilter: ^BodyFilter,
	//     shapeFilter: ^ShapeFilter
	// ) -> bool
}
