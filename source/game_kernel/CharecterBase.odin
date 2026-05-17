package game_kernel
import "core:log"
import "base:runtime"
import vmem "core:mem/virtual"
import psy "../physics"
import fixed "core:math/fixed"
import "../utils"


// this is just a type alieas so I can define it in multiple places

//todo we may need to change this
CHARACTER_CAPSULE_HALF_HEIGHT: i16 : 2
CHARACTER_CAPSULE_RADIUS: i16 : 1

HIT_BOX_MAX :: 64 // we may want to change this

CharecterSerlizedState :: struct($CU:typeid) {
   	health: 		   u32,
    end_in_hardknockdown:bool, // these flags are for if you end hitstun in hard or soft knockdown
    end_in_softknockdown:bool,
	body:              psy.FixedBody,
    p1_side:           bool,
   	move_dir:          Vec3,
   	in_air:            bool,
   	jump_requested:    bool,
   	jump_height:       psy.Fixed12_4,
   	move_speed:        psy.Fixed12_4,
   	air_move_speed:    psy.Fixed12_4,
    grav:              psy.Fixed12_4,
   	hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
   	entity_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of what entitys are active
   	current_frame:     int,
    current_state:     int, // this is an index
    hit_stun_frames:   u8,
    block_stun_frames: u8,
    combo_scaling:     u32,
    throw_protected:bool, // this is used to check if the player can be thrown
    charecter_info: CU,
   	charecter_flags: bit_field u32 {

	}, // lots of flags for various states.. tuble extc
}



//rename to charecter base
CharecterBase :: struct($CU:typeid) {
    max_health:           u32,
	arena:                vmem.Arena,
	//do I want to add an arena here
	using serlized_state: CharecterSerlizedState(CU),
	collision_box:        psy.FixedBox,
	//for all of these we may want to move them to the move
	// or we want to have a state that we then change off the charecter animation
	// or we move this to a reaction in the move itself
	soft_knockdown_index: int,
	hard_knockdown_index: int,
	hit_stun_index:       int, // we may replace this with a constent
	block_stun_index:     int,
	throw_reaction_index: int,
	//could move all these to the world
	states:               [dynamic]State(CharecterBase(CU),CU), // should this be state
	patterns:             [dynamic]Pattern,
    entity_pool:   	      [dynamic]Entity(CU), // this is the pool of entitys that we can spawn
    using hooks:          CharecterHooks(CU),
}


initilize_charecter_memory :: proc(char: ^CharecterBase($CU)) {
	arena_alocator := vmem.arena_allocator(&char.arena)
	char.patterns = make([dynamic]Pattern,arena_alocator)
	char.states = make([dynamic]State(CharecterBase(CU),CU),arena_alocator)
	char.entity_pool = make([dynamic]Entity(CU),arena_alocator)
}

setup_charecter :: proc(char: ^CharecterBase($CU)) {
	for &entity in char.entity_pool {
		log.debug("setting up enitty")
		//
		setup_entity(&entity,char)
	}
}



//todo this is an ordering update. because we do pickstate -> physics_update
charecter_update :: proc(character: ^CharecterBase($CU),other:^CharecterBase(CU),input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),w:^World(CU)) {

    //if we are greater than zero p1 side else p2 side
    character.serlized_state.p1_side = !(fixed.sub(character.serlized_state.body.position.x,other.serlized_state.body.x).i > (psy.Fixed12_4 {}).i)
    // log.debug("in charecter update")
	character.jump_requested = false // should this be reset here
	// character.addional_velocity = {} // do we want to reset this here

	// log.debug("getting current state")
	state,frame := charecter_get_current_state_frame(character^)
	proposed_state_index := pick_state(input_buffer, character.patterns,character.in_air)
	// log.debug("done getting state")

	state_frame_len := len(state.frames)

	exit_check := frame.check_exit(character, proposed_state_index)
	//exit check has to be true and we have to be at the end. but if exit check is true we can end pre maturely
	if (character.current_frame >= state_frame_len && exit_check == true) || exit_check == true {
		// if we were in hitstun and we want to go to another state
	    if(character.current_state == character.hit_stun_index) {
			//this is the recovery point
			w.combo_counter = 0
			character.combo_scaling = 100
			if character.end_in_hardknockdown do proposed_state_index = character.hard_knockdown_index
			if character.end_in_softknockdown do proposed_state_index = character.soft_knockdown_index
		}
		//if we are exiting a hard knock down reset the hardknockdown flag
		if character.serlized_state.end_in_hardknockdown && character.serlized_state.current_state  == character.hard_knockdown_index {
            character.serlized_state.end_in_hardknockdown=false
		}
		if character.serlized_state.end_in_softknockdown && character.serlized_state.current_state  == character.soft_knockdown_index {
            character.serlized_state.end_in_softknockdown=false
		}

		state,frame = charecer_change_state(character,proposed_state_index)
		// log.debug("new state needed")
	}

	// log.debug("finished picking state")
	if character.hit_stun_frames > 0 && character.current_state != character.hit_stun_index {
		state,frame =  charecer_change_state(character,character.hit_stun_index)
	} else if character.block_stun_frames > 0 && character.current_state != character.block_stun_index{
		state,frame = charecer_change_state(character,character.block_stun_index)
	}

	frame.on_frame(character,w) // run frame update
	for &updates in character.on_update {
		updates(character,w)
	}
	character.current_frame += 1 // incrment the fraem by 1
	for &entity in character.entity_pool {
		if entity.active == true {
			entity_update(&entity,character,w)
		}
	}
	//reduce hit and block stun frames
	if character.hit_stun_frames > 0 {
		character.hit_stun_frames -= 1
	}
	if character.block_stun_frames > 0 {
		character.block_stun_frames -= 1
	}
	// log.debug("done with charecter update")
}

charecter_side_effect :: proc(character:CharecterBase($CU),world:World(CU),inRollback:bool) {
    state,frame := charecter_get_current_state_frame(character^)
    frame.side_effect(character,world,inRollback)
}

charecer_change_state :: proc(character:^CharecterBase($CU),state:int) -> (State(CharecterBase(CU),CU),Frame(CharecterBase(CU),CU)) {
	character.current_state = state
	character.current_frame = 0
	character.jump_requested = false
	//reset state hit track flags
	for i:=0;i<63;i+=1 {
		character.hit_box_tracker_bit_mask -= {i} // All bits set to 0
	}

	state := character.states[character.current_state]
	frame := state.frames[character.current_frame]
	return state,frame
}

charecter_get_current_state_frame :: proc(character: CharecterBase($CU)) -> (State(CharecterBase(CU),CU),Frame(CharecterBase(CU),CU)) {
	state := character.states[character.current_state]
	frame_to_pick := character.current_frame
	state_frame_len := len(state.frames)
	if character.current_frame >= state_frame_len {
		frame_to_pick = state_frame_len - 1 // lock on the last frame if we can progress
	}
	frame := state.frames[frame_to_pick]
	return state, frame
}

// should we inline this

// may want to put this in moves
InputBfrPtrArr :: ^[2]^utils.Buffer(INPUT_BUFFER_LENGTH,Input)
HitBoxCtx :: struct($T,$CU:typeid) {
	self:   ^CharecterBase(CU),
	other:   ^CharecterBase(CU),
	self_buffer: ^utils.Buffer(INPUT_BUFFER_LENGTH,Input),
	other_buffer: ^utils.Buffer(INPUT_BUFFER_LENGTH,Input),
	hitbox_tracker_ptr: ^bit_set[0..<64; u64],
	hitbox_index: int,
	hitbox:       ^Hit_box,
	world: 		  ^World(CU),
	self_state:State(T,CU),
	extra:^T,
}
// CheckHitCtx :: struct {
//     state_params:^StateParams,
//     frame: FrameParams,
//     body: ^psy.FixedBody,
//     hitbox_tracking_ptr:^bit_set[0..<64; u64],//pointer to bit mask of if the hit box has been used,
// }
// construct_checkhit_ctx :: proc(self:^CharecterBase($CU)) -> CheckHitCtx{
//     state,frame:=charecter_get_current_state_frame(self^)
//     return CheckHitCtx{
//         state_params=&state.params,
//         frame=frame,
//         body=&self.body,
//         hitbox_tracking_ptr=&self.serlized_state.hit_box_tracker_bit_mask,
//     }
// }
CheckHitResult :: struct{
    hit_box_index:int,
    hurt_box_index:int,
    other_state:^StateParams, // this should not be modifyed its a pointer so its small and fast
    other_body:^psy.FixedBody,
}
//bruh this shit about to get funky
character_check_hit :: proc(self: ^CharecterBase($CU),other:^CharecterBase(CU),world:^World) -> [dynamic]CheckHitResult {
	//this should be cleared every frame because we can recalculate it
	hit_results := make_dynamic_array([dynamic]CheckHitResult,context.temp_allocator)
    self_state,self_frame:=charecter_get_current_state_frame(self^)
    other_state,other_frame:=charecter_get_current_state_frame(other^)

	for hitbox_index in other_frame.hitbox_list {
		//todo make me a function once we unify
		hit_box := other_state.moveboxs[hitbox_index].(Hit_box)
		for hurt_box_index in self_frame.hurtbox_list {
			hurt_box := self_state.moveboxs[hurt_box_index].(Hurt_box)
			col_check_res := psy.check_body_body_collsion(
			    hurt_box.box,
    			other.body,hit_box.box,
    			self.body,
			)
			//if we collide and we havent used the hitbox yet this state
			if col_check_res == true && hitbox_index in other.serlized_state.hit_box_tracker_bit_mask == false{
				append_elem(&hit_results, CheckHitResult{
    				hit_box_index=hitbox_index,
    				hurt_box_index=hurt_box_index,
    				other_state=&other.states[other.serlized_state.current_state].params,
                    other_body=&other.body,
				})
				hitbox_tracker := &other.serlized_state.hit_box_tracker_bit_mask
				hitbox_tracker^ += {hurt_box_index}
			}
		}
	}
	//loop through entitys
	for i:=0;i<len(other.entity_pool);i+=1 {
		entity := &other.entity_pool[i]
		if entity.active == true {
		    entity_state,entity_frame := get_entity_state_frame(entity^)
 			for hitbox_index in entity_frame.hitbox_list {
				//todo make me a function once we unify
				hit_box := entity_state.moveboxs[hitbox_index].(Hit_box)
				for hurt_box_index in self_frame.hurtbox_list {
   					hurt_box := self_state.moveboxs[hurt_box_index].(Hurt_box)
   					col_check_res := psy.check_body_body_collsion(
   					    hurt_box.box,
       					entity.body,hit_box.box,
       					self.body,
   					)
    					//if we collide and we havent used the hitbox yet this state
    				if col_check_res == true && hitbox_index in entity.serlized_state.hit_box_tracker_bit_mask == false{
    					append_elem(&hit_results, CheckHitResult{
            				hit_box_index=hitbox_index,
            				hurt_box_index=hurt_box_index,
            				other_state=&entity.states[entity.current_state].params,
                            other_body=&other.body,
    					})
    					hitbox_tracker := &entity.serlized_state.hit_box_tracker_bit_mask
    					hitbox_tracker^ += {hurt_box_index}
    				}
    			}
    		}
		}
	}
	return hit_results
}
// the other player hands you a list of places that they hit you and you must resolve those interactions
char_resolve_hit :: proc(
    self:^CharecterBase($CU),
    other:^CharecterBase(CU),
    hit_results_from_other:[dynamic]CheckHitResult,
    self_buffer:utils.FrameTrackedBuffer(INPUT_BUFFER_LENGTH,Input),
    world:^World(CU),
) {
    // self_state,_ := charecter_get_current_state_frame(self^)
   	side_mod: psy.Fixed12_4 = psy.init_from_parts(1,0)
	if self.p1_side == true do side_mod = psy.init_from_parts(-1,0)

	for &hit_results in hit_results_from_other {
	    block := charecter_check_block(self,self_buffer)
		// log.debug(hit_results)
		//we do this so that we can acccess entity info
		other_state := hit_results.other_state
		hit_box := other_state.moveboxs[hit_results.hit_box_index].(Hit_box)
		// hurt_box := other_state.moveboxs[hit_results.hurt_box_index].(Hurt_box)
		if block == true {
		    // if blocking
			knockback := hit_box.blockKnockback
      		pushback := hit_box.blockPushback

      		knockback.x = fixed.mul(knockback.x ,side_mod)
      		pushback.x = fixed.mul(pushback.x ,side_mod)

            psy.add_fixed_vec2_to_vel(&self.serlized_state.body,knockback)
            //we use other_body that way we can use this with projectiles
            psy.add_fixed_vec2_to_vel(hit_results.other_body,pushback)
 			self.block_stun_frames = hit_results.other_state.blockstun
			charecer_change_state(self,self.block_stun_index)
		} else {
		    //if hitting
			knockback := hit_box.hitKnockback
      		pushback := hit_box.hitPushback

      		knockback.x = fixed.mul(knockback.x ,side_mod)
      		pushback.x = fixed.mul(pushback.x ,side_mod)

            psy.add_fixed_vec2_to_vel(hit_results.other_body,pushback)
            psy.add_fixed_vec2_to_vel(&self.serlized_state.body,knockback)

 			self.hit_stun_frames = other_state.hitstun

            self.serlized_state.block_stun_frames = 0
            world.combo_counter += 1

 			if other.serlized_state.combo_scaling == 0 {
				//do we want to do this to avoid 0% scalling
				other.serlized_state.combo_scaling = 1
			}
			if  knockback.y.i > 0 {
			    //this is dumb we need a better way to do this
			    self.jump_requested=true
			}

			if other_state.hard_knockdown == true {
                self.serlized_state.end_in_hardknockdown = true
			} else if other_state.soft_knockdown == true {
                self.serlized_state.end_in_softknockdown = true
			}
			log.debug("about to dammage hook")
			dammage := other.hooks.damage_formula(
			    other^,
				self^,
				world^,
				other.hooks.charecter_check_counterhit(other^,self^), // is counter hit todo detect counterhit
				other_state^,
				hit_box,
			)
			self.serlized_state.health -= dammage
			charecer_change_state(self,self.hit_stun_index)
			world.hit_stop += other_state.hitstop
		}
	}
}



charecter_check_block ::proc(charecter:  ^CharecterBase($CU),input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input)) -> bool {
	input := input_buffer.buffer[input_buffer.index]
	state,_ := charecter_get_current_state_frame(charecter^)

	#partial switch input.dir {
	case Direction.Back:
		return true && charecter.hit_stun_index <= 0 && state.block_cancelable
	case Direction.DownBack:
		return true && charecter.hit_stun_index <= 0 && state.block_cancelable
	case:
		return false
	}
}




//todo fully move the velocity control to the moves
charecter_physics_update :: proc(character: ^CharecterBase($CU),other:^CharecterBase(CU), w: ^World(CU)) {
	character.body.prev_position = character.body.position
	character.body.prev_velocity = character.body.velocity
	jump_pressed := character.jump_requested
	if character.in_air && jump_pressed {
		jump_pressed = false // there is a better way to do this
	}
	// Add gravity
	// add me as a charecter peramiter
	gravity := psy.invert_fixed(character.serlized_state.grav) // needed bc negitive 0 is stinky
    character.body.velocity.y = fixed.add(character.body.velocity.y,gravity)
    ground_collision := psy.check_horizontal_plane_col(psy.set_box_by_body(character.collision_box,character.body),fixed.add(w.stage.floor.y,w.stage.floor.extent.y),false)
    charecter_was_in_air := character.in_air
	character.in_air = !ground_collision
	if ground_collision && jump_pressed == false {
	    // push player above ground
	    // resolve collisions
		// character.body.position.y = fixed.add(w.stage.floor.position.y,psy.f64_to_fixed(CHARACTER_CAPSULE_HALF_HEIGHT))
		character.body.velocity.y = psy.Fixed12_4 {}
		if charecter_was_in_air {
			character.body.velocity.x = psy.Fixed12_4 {}
			character.body.y = fixed.add(w.stage.floor.y,w.stage.floor.extent.y)
		}
	}
    other_player_collision := psy.check_body_body_collsion(
        character.collision_box,
        character.body,
        other.collision_box,
        other.body,
    )
    if other_player_collision {
        // step 1 move them outside
        // this is so bad bug my brain doesnt want to physics
       psy.add_fixed_vec2_to_vel(&other.body,psy.Vec2Fixed{character.serlized_state.body.velocity.x,psy.Fixed12_4{}})
       psy.add_fixed_vec2_to_vel(&character.body,psy.Vec2Fixed{other.serlized_state.body.velocity.x,psy.Fixed12_4{}})
    }
	// log.debug(character.velocity)


	// new_velocity += character.addional_velocity
	// set the velocity to the character
	// log.debug(psy.unfix_body(character.body))
	psy.move_by_vel(&character.body) // this moves by vel_tmp
	// log.debug(psy.unfix_body(character.body))

	// resolve floor wall and player colisions

	// read the new position into our structure
	//todo all this is gonna get removed
	for &physcis_update in character.on_physics_update {
		physcis_update(character,w)
	}
	for &entity in character.entity_pool {
		if entity.active {
			entity_physics_update(&entity,character,w)
		}
	}
}


delete_charecter :: proc(char: ^CharecterBase($CU)) {
	log.debug("delting charecers")
	vmem.arena_destroy(&char.arena)
}



serlize_charecter :: proc(char:CharecterBase($CU),allocator:runtime.Allocator) -> (CharecterSerlizedState(CU),[dynamic]SerlizedEntityState) {
    entitys := make([dynamic]SerlizedEntityState,allocator)
    for i := 0 ; i<len(char.entity_pool);i+=1 {
        append_elem(&entitys,serlize_entity(char.entity_pool[i]))
    }
    // log.debug(entitys[:])
    return char.serlized_state,entitys
}
deserlize_charecter :: proc(state:CharecterSerlizedState($CU),entitys_states:[dynamic]SerlizedEntityState,char:^CharecterBase(CU)) {
    char.serlized_state = state
    assert(len(entitys_states) == len(char.entity_pool),"entity pool must match the size of the serlized state")
    for i := 0 ; i<len(char.entity_pool);i+=1 {
    	// log.debug("deserlizing entity")
        deserlize_entity(entitys_states[i],&char.entity_pool[i])
    }
    //todo deserlize entity here
}
