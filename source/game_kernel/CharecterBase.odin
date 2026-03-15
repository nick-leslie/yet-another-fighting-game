package game_kernel
import "core:log"
import "base:runtime"
import vmem "core:mem/virtual"
import psy "../physics"
import fixed "core:math/fixed"
import "../utils"


// this is just a type alieas so I can define it in multiple places


CHARACTER_CAPSULE_HALF_HEIGHT: f64 : 2
CHARACTER_CAPSULE_RADIUS: f64 : 1

HIT_BOX_MAX :: 64 // we may want to change this

CharecterSerlizedState :: struct {
   	health: 		   u32,
	body:              psy.FixedBody,
   	move_dir:          Vec3,
   	jump_requested:    bool,
   	in_air:            bool,
   	jump_height:       f64,
   	move_speed:        f64,
   	air_move_speed:    f64,
   	air_drag:          f64,
   	hit_box_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of if the hit box has been used
   	entity_tracker_bit_mask: bit_set[0..<64; u64],// bit mask of what entitys are active
   	current_frame:     int,
    current_state:     int, // this is an index
    hit_stun_frames:   u32,
    block_stun_frames: u32,
    p1_side:           bool,
   	charecter_flags: bit_field u64 {

	}, // lots of flags for various states.. tuble extc
}

//rename to charecter base
CharecterBase :: struct {
	arena:             vmem.Arena,
	//do I want to add an arena here
	using serlized_state: CharecterSerlizedState,
	collision_box:     psy.FixedBox,
	states:            [dynamic]State(CharecterBase), // should this be state
	patterns:          [dynamic]Pattern,
	hit_stun_index:    int, // we may replace this with a constent
	block_stun_index:  int,
    entity_pool:   	   [dynamic]Entity, // this is the pool of entitys that we can spawn
	update:            proc(self:^CharecterBase,world:^World),
	physcis_update:    proc(self:^CharecterBase,world:^World),
	on_hit:			   proc(self:^CharecterBase,hit_ctx:HitBoxCtx(CharecterBase)),
	on_block:		   proc(self:^CharecterBase,hit_ctx:HitBoxCtx(CharecterBase)),
}


initilize_charecter_memory :: proc(char: ^CharecterBase) {
	arena_alocator := vmem.arena_allocator(&char.arena)
	char.patterns = make([dynamic]Pattern,arena_alocator)
	char.states = make([dynamic]State(CharecterBase),arena_alocator)
	char.entity_pool = make([dynamic]Entity,arena_alocator)
}

setup_charecter :: proc(char: ^CharecterBase) {
	for &entity in char.entity_pool {
		log.debug("setting up enitty")
		//
		setup_entity(&entity,char)
	}
}



//todo this is an ordering update. because we do pickstate -> physics_update
charecter_update :: proc(character: ^CharecterBase,input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),w:^World) {
	// log.debug("in charecter update")
	character.jump_requested = false // should this be reset here
	character.move_dir = {}
	// character.addional_velocity = {} // do we want to reset this here

	// log.debug("getting current state")
	state,frame := charecter_get_current_state_frame(character^)
	proposed_state_index := pick_state(input_buffer, character.patterns)
	// log.debug("done getting state")

	state_frame_len := len(state.frames)

	exit_check := frame.check_exit(character, proposed_state_index)
	//exit check has to be true and we have to be at the end. but if exit check is true we can end pre maturely
	if (character.current_frame >= state_frame_len && exit_check == true) || exit_check == true {
		if(character.current_state == character.hit_stun_index) {
			//this is the recovery point
			w.combo_counter = 0
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

charecer_change_state :: proc(character:^CharecterBase,state:int) -> (State(CharecterBase),Frame(CharecterBase)) {
	character.current_state = state
	character.current_frame = 0
	character.jump_requested = false

	state := character.states[character.current_state]
	frame := state.frames[character.current_frame]
	return state,frame
}

charecter_get_current_state_frame :: proc(character: CharecterBase) -> (State(CharecterBase), Frame(CharecterBase)) {
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
CharPtrArr :: ^[2]^CharecterBase
InputBfrPtrArr :: ^[2]^utils.Buffer(INPUT_BUFFER_LENGTH,Input)
HitBoxCtx :: struct($T:typeid) {
	charecters:   CharPtrArr,
	input_buffers:InputBfrPtrArr, // todo this may be bad
	hitbox_tracker_ptr: ^bit_set[0..<64; u64],
	hitbox_index: int,
	hitbox:       ^Hit_box,
	world: 		  ^World,
	self_state:State(T),
}
//bruh this shit about to get funky
character_check_hit :: proc(characters: CharPtrArr,input_buffers:InputBfrPtrArr, w:^World) {
	state, frame := charecter_get_current_state_frame(characters[0]^)
	for &hitbox_index in frame.hitbox_list {
		//todo make me a function once we unify
		hit_box := state.hit_boxes[hitbox_index]
		hitbox_context := HitBoxCtx(CharecterBase) {
			self_state = state,
			charecters   = characters,
			hitbox       = &hit_box,
			hitbox_index = hitbox_index,
			hitbox_tracker_ptr = &characters[0].hit_box_tracker_bit_mask,
			input_buffers = input_buffers,
			world 	   	 = w,
		}
		check_hit(hitbox_context)
	}
	// should we make this a function in entity
	// for &entity in characters[0].entity_pool {
	// 	if entity.active {
	// 		// enity_state := entity.states[entity.current_state]
	// 		// enity_frame := enity_state.frames[entity.current_frame]
	// 		//todo sub in non jolt physics collision
	// 	}
	// }
}


check_hit ::  proc (hit_ctx: HitBoxCtx(CharecterBase)) {
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
		hit_ctx.hitbox_tracker_ptr^ += {hit_ctx.hitbox_index} // todo check this
        //check if blocking and set to block or hit_stun
    }
}

charecter_check_block ::proc(charecter:  ^CharecterBase,input_buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input)) -> bool {
	input := input_buffer.buffer[input_buffer.index]
	#partial switch input.dir {
	case Direction.Back:
		return true
	case Direction.DownBack:
		return true
		// this is where we decide up back or down back
	case:
		return false
	}
}




//todo fully move the velocity control to the moves
charecter_physics_update :: proc(character: ^CharecterBase, w: ^World) {
	character.body.prev_position = character.body.position
	character.body.prev_velocity = character.body.velocity
	jump_pressed := character.jump_requested
	if character.in_air && jump_pressed {
		jump_pressed = false // there is a better way to do this
	}
	// Add gravity
	gravity := psy.f64_to_fixed(-.02) // todo change me
    character.body.velocity.y = fixed.add(character.body.velocity.y,gravity)

	if psy.check_horizontal_plane_col(psy.set_box_by_body(character.collision_box,character.body),w.stage.floor.y,false) {
	    // resolve collisions
		// character.body.position.y = fixed.add(w.stage.floor.position.y,psy.f64_to_fixed(CHARACTER_CAPSULE_HALF_HEIGHT))
		character.body.velocity.y = psy.Fixed12_4 {}
	}
	// log.debug(character.velocity)


	// new_velocity += character.addional_velocity
	// set the velocity to the character
	// log.debug(character.move_dir)
	// log.debug(psy.unfix_body(character.body))
	psy.move_by_vel(&character.body) // this moves by vel_tmp
	// log.debug(psy.unfix_body(character.body))

	// resolve floor wall and player colisions

	// read the new position into our structure
	//todo all this is gonna get removed

	for &entity in character.entity_pool {
		if entity.active {
			entity_physics_update(&entity,character,w)
		}
	}
}


delete_charecter :: proc(char: ^CharecterBase) {
	log.debug("delting charecers")
	vmem.arena_destroy(&char.arena)
}



serlize_charecter :: proc(char:CharecterBase,allocator:runtime.Allocator) -> (CharecterSerlizedState,[dynamic]SerlizedEntityState) {
    entitys := make([dynamic]SerlizedEntityState,allocator)
    for i := 0 ; i<len(char.entity_pool);i+=1 {
        append_elem(&entitys,serlize_entity(char.entity_pool[i]))
    }
    return char.serlized_state,entitys
}
deserlize_charecter :: proc(state:CharecterSerlizedState,entitys_states:[dynamic]SerlizedEntityState,char:^CharecterBase) {
    char.serlized_state = state
    assert(len(entitys_states) == len(char.entity_pool),"entity pool must match the size of the serlized state")
    for i := 0 ; i<len(char.entity_pool);i+=1 {
    	// log.debug("deserlizing entity")
        deserlize_entity(entitys_states[i],&char.entity_pool[i])
    }
    //todo deserlize entity here
}
