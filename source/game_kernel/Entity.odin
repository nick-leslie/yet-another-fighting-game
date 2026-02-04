package game_kernel

import vmem "core:mem/virtual"
import "base:runtime"

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
	// physics
	using position:    Vec3,
	velocity:          Vec3,
	prev_position:     Vec3, // do we need
	prev_velocity:	   Vec3, // do we need
	current_state_flags: struct { // we may want to remove this
		hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
	},
	//not stored for rollback
	states:            [dynamic]State(Entity), // should this be state
	activate:          proc(self:^Entity,charecter:^CharecterBase,world:^World), // this runs onetime
	update:            proc(self:^Entity,charecter:^CharecterBase,world:^World),
	on_hit:			   proc(self:^Entity,hit_ctx:HitBoxCtx),
	physcis_update:    proc(self:^Entity,charecter:^CharecterBase,world:^World),
	deactivate:        proc(self:^Entity,charecter:^CharecterBase,world:^World),
}


setup_entity :: proc(entity:^Entity,charecter:^CharecterBase,pm:Physics_Manager) {
	charecter_allocatior := vmem.arena_allocator(&charecter.arena)
	setup_entity_physics(entity,pm,charecter_allocatior) // look into odin auto pass pointers

}

// do we want to
activate_entity :: proc(character:^CharecterBase,entity_index:int,world:^World) {
	entity := &character.entity_pool[entity_index]
	entity.activate(entity,character,world)
	entity.active = true
}

entity_update :: proc(entity:^Entity,charecter:^CharecterBase,world:^World) {
	entity.update(entity,charecter,world)
}


entity_physics_update::proc(entity:^Entity,charecter:^CharecterBase,world:^World) {
	state := entity.states[entity.current_state]
	frame := state.frames[entity.current_frame]
	remove_state_hurtboxes(frame.hurtbox_list,world.physicsManager)
	entity.physcis_update(entity,charecter,world)
}


deactivate_entity :: proc(entity:^Entity,character:^CharecterBase) {
	entity.active = false
	//todo remove

}



setup_entity_physics :: proc (entity:^Entity,pm:Physics_Manager,allocator: runtime.Allocator) {
	for &state in entity.states {
		setup_move_bodys(&state,pm,allocator)
	}
}
