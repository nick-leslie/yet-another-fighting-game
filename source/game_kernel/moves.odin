package game_kernel

import "../../libs/jolt"
import "core:log"

State :: struct {
	frames:        [dynamic]Frame,
	hurtbox_bodys: [dynamic]^jolt.Body, // all these bodys are precreated or alocated but asleep
	// should all this be in a seprate struct
	canBlock:      bool,
	isAttack:      bool,
	hitstun:       u32,
	blockstun:     u32,
	damage:        u32,
}

AttackDir :: enum {
	Mid,
	High,
	Low,
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

check_cancel_options :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
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

jump_state_cancel :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
	//todo make it so we only cansle jump state when we land or do a
	// jump normal/special

	if char.in_air == false {
		return true
	}
	// assert(false,"not implmented")
	return false
}

free_cancel :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
	return true
}
no_cancel :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
	return false
}

exit_block_stun :: proc(char: ^CharecterBase, cancel_index: int) -> bool{
	if char.block_stun_frames <= 0 {
		return true
	}
	return false
}

exit_hit_stun :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
	// also check if we hit the ground post launch
	if char.hit_stun_frames <= 0 {
		return true
	}
	return false
}

Frame :: struct {
	frame_type:    FrameType,
	cancel_states: [dynamic]int,
	hurtbox_list:  [dynamic]Hurt_box, // width height extent will be static
	hitbox_list:   [dynamic]Hit_box,
	on_frame:      proc(_: ^CharecterBase),
	check_exit:    proc(_: ^CharecterBase, _: int) -> bool, // takes char pointer and proposed state
}

Hurt_box :: struct {
	using position: Vec3,
	extent:         Vec3, // width height extent will be static
	body:           ^jolt.Body, // all these bodys are precreated or alocated but asleep
	// todo properties
}
Hit_box :: struct {
	using position: Vec3,
	extent:         Vec3, // width height extent will be static
	hitPushback:    Vec3,
	blockPushback:  Vec3,
	attackDir:      AttackDir,
	// todo properties
}


FrameType :: enum {
	Startup,
	Active,
	Recovery,
}


//todo we may want to replace this with code gen
// man this sucks but we love it
setup_move_bodys :: proc(move: ^State,pm:Physics_Manager) {
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
					hurt_box.body = past_hurtboxes.body
					used_past = true
					break
				}
			}
			if used_past == true {
				continue // skip the rest of the loop
			}
			log.debug("past use previous")
			hurt_box_extent := hurt_box.extent * 0.5
			box_shape := jolt.BoxShape_Create(&hurt_box_extent, 0)
			log.debug("created box shape")
			box_settings := jolt.BodyCreationSettings_Create3(
				shape = auto_cast box_shape,
				position = &hurt_box.position,
				rotation = &QUAT_IDENTITY,
				motionType = .Static, // check this
				objectLayer = PHYS_LAYER_HURT_BOX,
			)
			log.debug("created created body")


			hurt_box.body = jolt.BodyInterface_CreateBody(
				pm.bodyInterface,
				box_settings,
			)
			log.debug(jolt.Body_GetID(hurt_box.body))
			jolt.BodyCreationSettings_Destroy(box_settings)
			append(&move.hurtbox_bodys, hurt_box.body)
			append(&past_hurtboxes, &hurt_box)
			jolt.Shape_Destroy(auto_cast box_shape)
		}
	}
}
