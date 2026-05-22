package game_kernel

import "core:log"
import psy "../physics"
@(require)import fixed "core:math/fixed"

/*
	ENTITY desighn doc
	all entitys are pre alocated for the charecter.
	they are then activated and dactivated
	they have states and frames like a charecter.
	they also have hooks like a charecter.
*/
//entity state should be stored  in the charecter
SerlizedEntityState :: struct {
	active:			   bool,
	id: 		   	   int,
	health: 		   u32,
	current_state: 	   int,
	current_frame: 	   int,
	move_speed:        psy.Fixed12_4,
	hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
	// physics
	body:              psy.FixedBody,
}

//todo could make a factory
// this may suck
Entity :: struct($CU:typeid) {
   	using serlized_state: SerlizedEntityState,
	charecter_ptr: 	   ^CharecterBase(CU),
	//not stored for rollbacks
	// can we have a compile time amount of states
	state_map: 		   [dynamic]int, // this is a map of what states can go into what. its the same state if there is no exit
	states:            [dynamic]State, // should this be state
	activate:          proc(self:^Entity(CU),charecter:^CharecterBase(CU),world:^World(CU)), // this runs onetime
	update:            proc(self:^Entity(CU),charecter:^CharecterBase(CU),world:^World(CU)),
	on_hit:            proc(self:^Entity(CU),hit_ctx:CheckHitResult,world:^World(CU)),
	on_block:          proc(self:^Entity(CU),hit_ctx:CheckHitResult,world:^World(CU)),
	physcis_update:    proc(self:^Entity(CU),charecter:^CharecterBase(CU),world:^World(CU)),
	deactivate:        proc(self:^Entity(CU),charecter:^CharecterBase(CU),world:^World(CU)),
}


setup_entity :: proc(entity:^Entity($CU),charecter:^CharecterBase(CU)) {
    log.debug("setups")
	entity.charecter_ptr = charecter
}

// do we want to
activate_entity :: proc(character:^CharecterBase($CU),entity_index:int,world:^World(CU)) {
	// log.debug(character.entity_pool)
	entity := &character.entity_pool[entity_index]
	entity.hit_box_tracker_bit_mask = {} // reset current state flags
	entity.activate(entity,character,world)
	entity.active = true
	log.debug(entity.active)
	// assert(false)
}

entity_update :: proc(entity:^Entity($CU),charecter:^CharecterBase(CU),world:^World(CU)) {
	state := entity.states[entity.current_state]
	frame := state.frames[entity.current_frame]
	exit_check := false
	// todo add a proposed state index here
	if frame.check_exit != nil do exit_check = charecter.hooks.moveCheckExit[frame.check_exit.(int)](charecter,entity.current_frame)
	if exit_check == true {
		entity.current_state = entity.state_map[entity.current_state]
		entity.current_frame = 0
	}
	if frame.on_frame  != nil{
	    charecter.hooks.onFrame[frame.on_frame.(int)](charecter,world)
	}
	if entity.current_frame > len(state.frames) {
		entity.current_frame += 1
	}
	entity.update(entity,charecter,world)
	//todo advance frame
}


entity_physics_update::proc(entity:^Entity($CU),charecter:^CharecterBase(CU),world:^World(CU)) {
	// state := entity.states[entity.current_state]
	// frame := state.frames[entity.current_frame]
	// remove_state_hurtboxes(frame.hurtbox_list,world.physicsManager)
	entity.physcis_update(entity,charecter,world)
	psy.move_by_vel(&entity.body)
	log.debug("done")
}


deactivate_entity :: proc(entity:^Entity($CU),character:^CharecterBase(CU),world:^World(CU)) {
	entity.active = false
	entity.current_state = 0
	entity.current_frame = 0
	entity.deactivate(entity,character,world)
	//todo remove
}

get_entity_state_frame :: proc(entity:Entity($CU))  -> (State, Frame) {
   	state := entity.states[entity.current_state]
	frame_to_pick := entity.current_frame
	state_frame_len := len(state.frames)
	if entity.current_frame >= state_frame_len {
		frame_to_pick = state_frame_len - 1 // lock on the last frame if we can progress
	}
	frame := state.frames[frame_to_pick]
	return state, frame
}







serlize_entity :: proc(char:Entity($C)) -> SerlizedEntityState {
    return char.serlized_state
}
deserlize_entity :: proc(state:SerlizedEntityState,entity:^Entity($C)) {
    entity.serlized_state = state
}
