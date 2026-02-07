package game_kernel

import "../../libs/jolt"
import "core:log"
import "base:runtime"

State :: struct($T:typeid) {
	name:		   string,
	frames:        [dynamic]Frame(T),
	hurtbox_bodys: [dynamic]^jolt.Body, // all these bodys are precreated or alocated but asleep
	hit_boxes: 	   [dynamic]Hit_box,
	// should all this be in a seprate struct
	canBlock:      bool,
	isAttack:      bool,
	hitstun:       u32,
	blockstun:     u32,
	damage:        u32,
}

Frame :: struct($T:typeid) {
	frame_type:    FrameType,
	cancel_states: [dynamic]int,
	hurtbox_list:  [dynamic]Hurt_box, // width height extent will be static we may want to make it an index
	hitbox_list:   [dynamic]int, // index into the hit box array of the state
	on_frame:      proc(_: ^T,world:^World),
	check_exit:    proc(_: ^T, _: int) -> bool, // takes char pointer and proposed state
}

Hurt_box :: struct {
	using position: Vec3,
	extent:         Vec3, // width height extent will be static
	body:           ^jolt.Body, // all these bodys are precreated or alocated but asleep
	// todo properties
}
//for multi hits spawn a new hitbox
Hit_box :: struct {
	using position:   Vec3,
	extent:           Vec3, // width height extent will be static
	hitKnockback:     Vec3, // this is applied to other
	hitPushback: 	  Vec3, // this is applied to self
	blockKnockback:   Vec3,
	blockPushback:    Vec3,
	attackDir:        AttackDir,
	// todo properties
}


FrameType :: enum {
	Startup,
	Active,
	Recovery,
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
	delete(move.hit_boxes)
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

remove_state_hurtboxes :: proc(hurt_box_list:[dynamic]Hurt_box,pm:Physics_Manager) {
	for &hurt_box in hurt_box_list {
		id := jolt.Body_GetID(hurt_box.body)
		jolt.BodyInterface_RemoveBody(pm.bodyInterface, id)
	}
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

on_hit_stun :: proc(char: ^CharecterBase) {
	char.hit_stun_frames-=1
}
on_block_stun :: proc(char: ^CharecterBase) {
	char.hit_stun_frames-=1
}

exit_hit_stun :: proc(char: ^CharecterBase, cancel_index: int) -> bool {
	// also check if we hit the ground post launch
	log.debug(char.hit_stun_frames)
	if char.hit_stun_frames <= 0 {
		return true
	}
	return false
}


//todo we may want to replace this with code gen
// man this sucks but we love it
setup_move_bodys :: proc(move: ^State($T),pm:Physics_Manager,arena_alocator:runtime.Allocator) {
	if len(move.hit_boxes) > HIT_BOX_MAX {
		assert(false,"we have more hit boxes than tracking flags please reduce the number of hit boxes 64 should be more than enough")
	}

	move.hurtbox_bodys = make([dynamic]^jolt.Body,arena_alocator)
	past_hurtboxes := make([dynamic]^Hurt_box,arena_alocator)
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
