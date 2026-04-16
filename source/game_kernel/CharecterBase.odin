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
	body:              psy.FixedBody,
   	move_dir:          Vec3,
   	jump_requested:    bool,
   	in_air:            bool,
   	jump_height:       psy.Fixed12_4,
   	move_speed:        psy.Fixed12_4,
   	air_move_speed:    psy.Fixed12_4,
    grav:              psy.Fixed12_4,
   	hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
   	entity_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of what entitys are active
   	current_frame:     int,
    current_state:     int, // this is an index
    hit_stun_frames:   u32,
    block_stun_frames: u32,
    p1_side:           bool,
    combo_scaling:     u32,
    charecter_info: CU,
    end_in_hardknockdown:bool, // these flags are for if you end hitstun in hard or soft knockdown
    end_in_softknockdown:bool,
   	charecter_flags: bit_field u64 {

	}, // lots of flags for various states.. tuble extc
}



//rename to charecter base
CharecterBase :: struct($CU:typeid) {
	arena:                vmem.Arena,
	//do I want to add an arena here
	using serlized_state: CharecterSerlizedState(CU),
	collision_box:        psy.FixedBox,
	soft_knockdown_index: int,
	hard_knockdown_index: int,
	states:               [dynamic]State(CharecterBase(CU),CU), // should this be state
	patterns:             [dynamic]Pattern,
	hit_stun_index:       int, // we may replace this with a constent
	block_stun_index:     int,
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
charecter_update :: proc(character: ^CharecterBase($CU),input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),w:^World(CU)) {
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
		state,frame = charecer_change_state(character,proposed_state_index)
		for i:=0;i<63;i+=1 {
			character.hit_box_tracker_bit_mask -= {i} // All bits set to 0
		}
		// log.debug("new state needed")
	}

	// log.debug("finished picking state")
	if character.hit_stun_frames > 0 && character.current_state != character.hit_stun_index {
		state,frame =  charecer_change_state(character,character.hit_stun_index)
		for i:=0;i<63;i+=1 {
			character.hit_box_tracker_bit_mask -= {i} // All bits set to 0
		}
	} else if character.block_stun_frames > 0 && character.current_state != character.block_stun_index{
		state,frame = charecer_change_state(character,character.block_stun_index)
		for i:=0;i<63;i+=1 {
			character.hit_box_tracker_bit_mask -= {i} // All bits set to 0
		}
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
//bruh this shit about to get funky
character_check_hit :: proc(self: ^CharecterBase($CU),other:^CharecterBase(CU),self_buffer:^utils.Buffer(INPUT_BUFFER_LENGTH,Input),other_buffer:^utils.Buffer(INPUT_BUFFER_LENGTH,Input), w:^World(CU)) {
	state, frame := charecter_get_current_state_frame(self^)
	for &hitbox_index in frame.hitbox_list {
		//todo make me a function once we unify
		hit_box := state.hit_boxes[hitbox_index]
		hitbox_context := HitBoxCtx(CharecterBase(CU),CU) {
			self_state         = state,
			self               = self,
			other              = other,
			hitbox             = &hit_box,
			hitbox_index       = hitbox_index,
			hitbox_tracker_ptr = &self.hit_box_tracker_bit_mask,
			self_buffer        = self_buffer,
			other_buffer       = other_buffer,
			world              = w,
			extra = nil,
		}
		check_hit(hitbox_context)
	}
	// should we make this a function in entity
	// todo why is this not working
	for &entity in self.entity_pool {
		if entity.active {
			enity_state := entity.states[entity.current_state]
			enity_frame := enity_state.frames[entity.current_frame]
			//todo sub in non jolt physics collision
			for &hitbox_index in enity_frame.hitbox_list {
				hit_box := enity_state.hit_boxes[hitbox_index]
				hitbox_context := HitBoxCtx(Entity(CU),CU) {
					self_state = enity_state,
					self   = self,
					other   = other,
					hitbox       = &hit_box,
					hitbox_index = hitbox_index,
					hitbox_tracker_ptr = &entity.hit_box_tracker_bit_mask,
					self_buffer =  self_buffer,
					other_buffer = other_buffer,
					world 	   	 = w,
					extra = &entity,
				}
				check_hit_entity(hitbox_context)
			}
		}
	}
}


check_hit ::  proc (hit_ctx: HitBoxCtx(CharecterBase($CU),CU)) {
	self := hit_ctx.self
	other := hit_ctx.other

	// self_buffer := hit_ctx.self_buffer
	other_buffer := hit_ctx.other_buffer

	_, frameOther := charecter_get_current_state_frame(other^)
	// we may want to speed this up later by seperating to a p1 layer



	side_mod: psy.Fixed12_4 = psy.init_from_parts(1,0)
	if other.p1_side == false do side_mod = psy.init_from_parts(-1,0)


   	for &hurt_box in frameOther.hurtbox_list {
        col_check_res := psy.check_body_body_collsion(hurt_box,other.body,hit_ctx.hitbox.box,self.body)
        log.debug(col_check_res)
        if col_check_res == false{
            continue // skip to the next hurt box
        }
        block := charecter_check_block(other,other_buffer^)



		other.body.velocity = psy.Vec2Fixed{}
		//this sets it so we dont hit with the same hitbox for multiple frames

        if block == false && hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false { // the in is checking if its set

            knockback := hit_ctx.hitbox.hitKnockback
      		knockback.x = fixed.mul(knockback.x ,side_mod)
      		pushback := hit_ctx.hitbox.hitPushback
      		pushback.x = fixed.mul(pushback.x ,side_mod)


            psy.add_fixed_vec2_to_vel(&self.body,pushback)
            psy.add_fixed_vec2_to_vel(&other.body,knockback)
            // hit
			//todo set self current velocity
			other.hit_stun_frames = hit_ctx.self_state.hitstun
			other.block_stun_frames=0
			hit_ctx.world.combo_counter += 1
			if self.combo_scaling == 0 {
				//do we want to do this to avoid 0% scalling
				self.combo_scaling = 100
			}
			if  knockback.y.i > 0 {
			    other.jump_requested=true
			}
			//set in hit_stun
			dammage := self.damage_formula(
			    self^,
				other^,
				hit_ctx.world^,
				self.charecter_check_counterhit(self^,other^), // is counter hit todo detect counterhit
				hit_ctx.self_state,
				hit_ctx.hitbox^,
			)
			other.health -= dammage
			charecer_change_state(other,other.hit_stun_index)
			hit_ctx.world.hit_stop+=hit_ctx.self_state.hitstop
		} else if hit_ctx.hitbox_index in hit_ctx.hitbox_tracker_ptr == false {
            // block
      		knockback := hit_ctx.hitbox.blockKnockback
    		knockback.x = fixed.mul(knockback.x ,side_mod)
    		pushback := hit_ctx.hitbox.blockPushback
    		pushback.x = fixed.mul(pushback.x ,side_mod)

            psy.add_fixed_vec2_to_vel(&self.body,pushback)
            psy.add_fixed_vec2_to_vel(&other.body,knockback)

			other.block_stun_frames = hit_ctx.self_state.blockstun
			charecer_change_state(other,other.block_stun_index)
			// other.block_stun_frames=0

			// other.hit_stun_frames=0
		}
		hit_ctx.hitbox_tracker_ptr^ += {hit_ctx.hitbox_index} // todo check this
        //check if blocking and set to block or hit_stun
    }
}


charecter_check_block ::proc(charecter:  ^CharecterBase($CU),input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input)) -> bool {
	input := input_buffer.buffer[input_buffer.index]
	#partial switch input.dir {
	case Direction.Back:
		return true && charecter.hit_stun_index <= 0
	case Direction.DownBack:
		return true && charecter.hit_stun_index <= 0
		// this is where we decide up back or down back
	case:
		return false
	}
}




//todo fully move the velocity control to the moves
charecter_physics_update :: proc(character: ^CharecterBase($CU), w: ^World(CU)) {
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
