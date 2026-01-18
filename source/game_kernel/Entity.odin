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
	states:            [dynamic]State, // should this be state
	activate:          proc(charecter:^CharecterBase,world:^World), // this runs onetime
	update:            proc(charecter:^CharecterBase,world:^World),
	on_hit:			   proc(hit_ctx:HitBoxCtx),
	physcis_update:    proc(charecter:^CharecterBase,world:^World),
	deactivate:        proc(charecter:^CharecterBase,world:^World),
}

create_entity :: proc(entity:^Entity,charecter:^CharecterBase,world:^World) {
	charecter_allocatior := vmem.arena_allocator(&charecter.arena)
	setup_entity_physics(entity,world^,charecter_allocatior) // look into odin auto pass pointers
}

// do we want to
activate_entity :: proc(character:^CharecterBase,entity_index:int,world:^World) {
	entity := &character.entity_pool[entity_index]
	entity.activate(character,world)
	entity.active = true

}

deactivate_entity :: proc(entity:^Entity,character:^CharecterBase) {
	entity.active = false
}


setup_entity_physics :: proc (entity:^Entity,world:World,allocator: runtime.Allocator) {
	for &state in entity.states {
		setup_move_bodys(&state,world.physicsManager,allocator)
	}
}
