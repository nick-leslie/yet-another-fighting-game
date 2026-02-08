package game_kernel

import vmem "core:mem/virtual"
import "base:runtime"
import "core:log"
import "../../libs/jolt"

/*
	ENTITY desighn doc
	all entitys are pre alocated for the charecter.
	they are then activated and dactivated
	they have states and frames like a charecter.
	they also have hooks like a charecter.



*/
//todo could make a factory
Entity :: struct {
	active:			   bool,
	id: 		   	   int,
	health: 		   u32,
	current_state: 	   int,
	current_frame: 	   int,
	move_speed:        f32,
	// physics
	using position:    Vec3,
	velocity:          Vec3,
	prev_position:     Vec3, // do we need
	prev_velocity:	   Vec3, // do we need
	current_state_flags: struct { // we may want to remove this
		hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
	},
	charecter_ptr: 	   ^CharecterBase,
	//not stored for rollback
	// can we have a compile time amount of states
	state_map: 		   [dynamic]int, // this is a map of what states can go into what. its the same state if there is no exit
	states:            [dynamic]State(Entity), // should this be state
	activate:          proc(self:^Entity,charecter:^CharecterBase,world:^World), // this runs onetime
	update:            proc(self:^Entity,charecter:^CharecterBase,world:^World),
	on_hit:			   proc(self:^Entity,hit_ctx:HitBoxCtx(Entity)),
	on_block:		   proc(self:^Entity,hit_ctx:HitBoxCtx(Entity)),
	physcis_update:    proc(self:^Entity,charecter:^CharecterBase,world:^World),
	deactivate:        proc(self:^Entity,charecter:^CharecterBase,world:^World),
}


setup_entity :: proc(entity:^Entity,charecter:^CharecterBase,pm:Physics_Manager) {
	charecter_allocatior := vmem.arena_allocator(&charecter.arena)
	setup_entity_physics(entity,pm,charecter_allocatior) // look into odin auto pass pointers
	entity.charecter_ptr = charecter
}

// do we want to
activate_entity :: proc(character:^CharecterBase,entity_index:int,world:^World) {
	// log.debug(character.entity_pool)
	entity := &character.entity_pool[entity_index]
	log.debug(entity)
	entity.activate(entity,character,world)
	entity.active = true
	log.debug(entity)
}

entity_update :: proc(entity:^Entity,charecter:^CharecterBase,world:^World) {
	state := entity.states[entity.current_state]
	frame := state.frames[entity.current_frame]
	exit := frame.check_exit(entity,entity.current_frame)
	if exit == true {
		entity.current_state = entity.state_map[entity.current_state]
		entity.current_frame = 0
	}
	frame.on_frame(entity,world)
	if entity.current_frame > len(state.frames) {
		entity.current_frame += 1
	}
	entity.update(entity,charecter,world)
	//todo advance frame
}


entity_physics_update::proc(entity:^Entity,charecter:^CharecterBase,world:^World) {
	state := entity.states[entity.current_state]
	frame := state.frames[entity.current_frame]
	remove_state_hurtboxes(frame.hurtbox_list,world.physicsManager)
	entity.physcis_update(entity,charecter,world)
	entity.position += entity.velocity
}


deactivate_entity :: proc(entity:^Entity,character:^CharecterBase,world:^World) {
	entity.active = false
	entity.current_state = 0
	entity.current_frame = 0
	entity.deactivate(entity,character,world)
	//todo remove
}



setup_entity_physics :: proc (entity:^Entity,pm:Physics_Manager,allocator: runtime.Allocator) {
	for &state in entity.states {
		setup_move_bodys(&state,pm,allocator)
	}
}

// is this needed
entity_on_hit_other ::  proc "c" (hit_ctx_ptr: rawptr, result: ^jolt.ShapeCastResult) {
	context = g_context // todo fix me
	hit_ctx: ^HitBoxCtx(Entity) = auto_cast (hit_ctx_ptr) //todo remove auto cast
	entity := hit_ctx.self
	self := CharPtrArr(hit_ctx.charecters)[0]
	other := CharPtrArr(hit_ctx.charecters)[1]

	// self_buffer := InputBfrPtrArr(hit_ctx.input_buffers)[0]
	other_buffer := InputBfrPtrArr(hit_ctx.input_buffers)[1]
	// entity_state := entity.states[entity.current_state]
	// entity_frame := state.frames[entity.current_frame]
	self_state, frame_self := charecter_get_current_state_frame(self^)
	_, frameOther := charecter_get_current_state_frame(other^)
	// we may want to speed this up later by seperating to a p1 layer
	for &hurt_box in frame_self.hurtbox_list {
		id := jolt.Body_GetID(hurt_box.body)
		if id == result.bodyID2 do return
	}

	if hit_ctx.world.stage.floor_id == result.bodyID2 do return // use layers to filter

	self_id := jolt.CharacterVirtual_GetInnerBodyID(self.physics_character)
	other_id := jolt.CharacterVirtual_GetInnerBodyID(other.physics_character)
	if self_id == result.bodyID2 do return
	if other_id == result.bodyID2 do return

	side_mod: f32 = 1.
	if other.p1_side == false do side_mod = -1.

	for &hurt_box in frameOther.hurtbox_list {
		id := jolt.Body_GetID(hurt_box.body)
		if id == result.bodyID2 {
			// log.debug(hurt_box)
			block := charecter_check_block(other,other_buffer^)
			//todo dont make a hurt box apply more than once durring a moves duration
			//todo fix me
			if block == false && hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false { // the in is checking if its set
				knockback := hit_ctx.hitbox.hitKnockback
				knockback.x *= side_mod
				pushback := hit_ctx.hitbox.hitPushback
				pushback.x *= side_mod
				other.velocity = knockback
				self.velocity += pushback

				//this sets it so we dont hit with the same hitbox for multiple frames
				hit_ctx.hitbox_tracker_ptr^ += {hit_ctx.hitbox_index} // todo check this

				//todo set self current velocity
				other.hit_stun_frames = self_state.hitstun
				other.block_stun_frames=0
				hit_ctx.world.combo_counter += 1
				//set in hit_stun
				other.health-= self_state.damage
				entity.on_hit(entity,hit_ctx^)
			} else if hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false {
				// log.debug("blocking")
				knockback := hit_ctx.hitbox.blockKnockback
				knockback.x *= side_mod
				pushback := hit_ctx.hitbox.blockPushback
				pushback.x *= side_mod
				other.velocity = knockback
				self.velocity += pushback
				//this sets it so we dont hit with the same hitbox for multiple frames
				hit_ctx.hitbox_tracker_ptr^ += {hit_ctx.hitbox_index} // todo check this
				other.block_stun_frames = self_state.blockstun

				other.hit_stun_index=0

				entity.on_block(entity,hit_ctx^)
			}
			//check if blocking and set to block or hit_stun
		}
	}
}
