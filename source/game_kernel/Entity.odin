package game_kernel

import "core:log"
import psy "../physics"

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
	body:              psy.FixedBody,
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


setup_entity :: proc(entity:^Entity,charecter:^CharecterBase) {
    log.debug("setups")
	entity.charecter_ptr = charecter
}

// do we want to
activate_entity :: proc(character:^CharecterBase,entity_index:int,world:^World) {
	// log.debug(character.entity_pool)
	entity := &character.entity_pool[entity_index]
	entity.current_state_flags = {} // reset current state flags
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
	log.debug("started entity physics update")
	// state := entity.states[entity.current_state]
	// frame := state.frames[entity.current_frame]
	// remove_state_hurtboxes(frame.hurtbox_list,world.physicsManager)
	entity.physcis_update(entity,charecter,world)
	psy.move_by_vel(&entity.body)
	log.debug("done")
}


deactivate_entity :: proc(entity:^Entity,character:^CharecterBase,world:^World) {
	entity.active = false
	entity.current_state = 0
	entity.current_frame = 0
	entity.deactivate(entity,character,world)
	//todo remove
}



//todo this is realy stinky and I dont like this get rid of it
check_hit_entity ::  proc (hit_ctx: HitBoxCtx(Entity)) {
	self := CharPtrArr(hit_ctx.charecters)[0]
	other := CharPtrArr(hit_ctx.charecters)[1]

	// self_buffer := InputBfrPtrArr(hit_ctx.input_buffers)[0]
	other_buffer := InputBfrPtrArr(hit_ctx.input_buffers)[1]
	_, frameOther := charecter_get_current_state_frame(other^)
	// we may want to speed this up later by seperating to a p1 layer



	side_mod: f64 = 1.
	if other.p1_side == false do side_mod = -1.


   	for &hurt_box in frameOther.hurtbox_list {
    col_check_res := psy.check_body_body_collsion(hurt_box,other.body,hit_ctx.hitbox.box,self.body)
        log.debug(col_check_res)
        if col_check_res == false{
            continue // skip to the next hurt box
        }
        block := charecter_check_block(other,other_buffer^)
		knockback := hit_ctx.hitbox.blockKnockback
		knockback.x *= side_mod
		pushback := hit_ctx.hitbox.blockPushback
		pushback.x *= side_mod
		psy.add_float_vec2_to_vel(&other.body,knockback)
		psy.add_float_vec2_to_vel(&self.body,pushback)
		//this sets it so we dont hit with the same hitbox for multiple frames
		hit_ctx.hitbox_tracker_ptr^ += {hit_ctx.hitbox_index} // todo check this

        if block == false && hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false { // the in is checking if its set
            // hit
			//todo set self current velocity
			other.hit_stun_frames = hit_ctx.self_state.hitstun
			other.block_stun_frames=0
			hit_ctx.world.combo_counter += 1
			//set in hit_stun
			other.health-= hit_ctx.self_state.damage
		} else if hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false {
            // block
			other.block_stun_frames = hit_ctx.self_state.blockstun
			other.hit_stun_index=0
		}
        //check if blocking and set to block or hit_stun
    }
}
