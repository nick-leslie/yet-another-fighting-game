#+feature dynamic-literals
#+vet !unused !using-stmt
package characters

import gk "../game_kernel"
@(require) import "core:log"
import psy "../physics"
import vmem "core:mem/virtual"
import "../tools"

// could use the marvel token bar but let both players influce it


Cyberpunk :: struct {
    light_fireball_entity_index:int,
    med_fireball_entity_index:int,
}

air_state_cancel_index :gk.function_index
cancelable_on_hit_or_block_index :gk.function_index
nutral_on_frame_index:gk.function_index
reset_velocity_index:gk.function_index
create_cyberpunk_charecter :: proc(pos:[4]i16,budget:i64) -> gk.CharecterBase(Charecter) {
    hooks := gk.CharecterHooks(Charecter) {
        damage_formula = gk.make_default_dammage_formula(Charecter),
        charecter_check_counterhit = gk.make_default_counterhit_check(Charecter),
	}
	log.debug(hooks)
   	charecter := gk.CharecterBase(Charecter) {
		health=200, // todo change me
		max_health=200,
		body = psy.body_init(pos),
		collision_box = psy.box_init({},{gk.CHARACTER_CAPSULE_RADIUS*2,0, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2,0}),
		move_speed = psy.init_from_parts(7,0),
		air_move_speed = psy.init_from_parts(10,0),
		jump_height = psy.init_from_parts(15,0),
		grav = psy.init_from_parts(1,5),
		p1_side = true,
		hooks = hooks,
		charecter_info=Charecter {
			budget=budget,
			charecter_spesific_data = Cyberpunk {
			},
		},
	}
   	gk.initilize_charecter_memory(&charecter)
	add_charecter_states(&charecter)
	return charecter
}


add_charecter_states:: proc(charecter:^gk.CharecterBase(Charecter)) {
    air_state_cancel_index = gk.push_function(&charecter.hooks.moveCheckExit,air_state_cancel)
    cancelable_on_hit_or_block_index = gk.push_function(&charecter.hooks.moveCheckExit,cancelable_on_hit_or_block)
   	nutral_on_frame_index = gk.push_function(&charecter.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		//todo if should we check if grounded?
		// we are going to have to change this

		if char.in_air == false {
		    char.body.velocity.x = psy.Fixed12_4 {}
		}
	})
   	add_universal_states(charecter)
	cyberpunk_add_state_movement(charecter) // the nill is tmp
	cyberpunk_add_punch_attacks(charecter)
	cyberpunk_add_fireball(charecter)
}


cyberpunk_add_state_movement ::proc(char: ^gk.CharecterBase(Charecter)) {
	log.debug("in add movement")
	index := cyberpunk_state_stand_neutral(char)
	cyberpunk_pattern_stand_neutral(char,index)

	index = cyberpunk_state_crouch_neutral(char)
	cyberpunk_pattern_crouch(char,index)

	index = cyberpunk_state_forward(char)
	cyberpunk_pattern_forward(char,index)

	index = cyberpunk_state_backward(char)
	cyberpunk_pattern_backward(char,index)

	index = cyberpunk_state_jump(char)
	cyberpunk_pattern_jump(char,index)

	index = cyberpunk_state_jump_forward(char)
	cyberpunk_pattern_jump_forward(char,index)

	index = cyberpunk_state_jump_backward(char)
	cyberpunk_pattern_jump_backward(char,index)
	log.debug("done adding movement")
}
any_cancel_index :gk.function_index
cyberpunk_state_stand_neutral ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index{
	context.allocator = vmem.arena_allocator(&char.arena)
	//todo we can load hitboxes
	// test := #load("/", []gk.Hit_box)
	hurt_box := gk.Hurt_box {
	    box = psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	any_cancel_index = gk.push_function(&char.hooks.moveCheckExit,any_cancel)
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =nutral_on_frame_index,
		check_exit = any_cancel_index,
	}
	move := gk.State {
		name="neutral",
		frames = {zero_frame},
		moveboxs={hurt_box},
	}
	return gk.charecter_push_state(char, move)
}
cyberpunk_state_crouch_neutral ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index{
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box= psy.box_init({0,0,0,0},{5,0,5,0}),
	}
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =nutral_on_frame_index,
		check_exit = any_cancel_index,
	}
	move := gk.State {
		name="neutral",
		frames = {zero_frame},
		moveboxs={hurt_box},
	}
	return gk.charecter_push_state(char, move)
}

cyberpunk_state_forward ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index{
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box = psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	forward_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		if char.p1_side do char.body.velocity.x = char.move_speed
		if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
	})
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =forward_on_frame_index,
		check_exit = any_cancel_index,
	}
	move := gk.State {
		name="forward",
		frames = {zero_frame},
		moveboxs={hurt_box},
	}
	log.debug("in setting up physics")
	return gk.charecter_push_state(char, move)
}


cyberpunk_state_backward ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index{
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box = psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	backward_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
    		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
    		if !char.p1_side do char.body.velocity.x = char.move_speed
	})
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =backward_on_frame_index,
		check_exit = any_cancel_index,
	}
	move := gk.State {
		name="backward",
		frames = {zero_frame},
		moveboxs={hurt_box},
	}

	return gk.charecter_push_state(char, move)
}
cyberpunk_state_jump ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index {
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	jump_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
	    char.jump_requested = true
		char.body.velocity.y = char.jump_height
	})
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =jump_on_frame_index,
		 // todo change me
	}
	one_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},

		check_exit = air_state_cancel_index, // todo change me
	}
	move := gk.State {
		name="nutral jump",
		frames = {zero_frame, one_frame},
		moveboxs={hurt_box},
	}

	return gk.charecter_push_state(char, move)
}


cyberpunk_state_jump_forward ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index {
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	jump_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
	    char.jump_requested = true
	    char.body.velocity.y = char.jump_height
	    if char.p1_side do char.body.velocity.x = char.air_move_speed
	    if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.air_move_speed)
	})
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame = jump_on_frame_index,
		 // todo change me
	}
	one_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},

		check_exit = air_state_cancel_index, // todo change me
	}
	move := gk.State {
		name="jump forward",
		frames = {zero_frame,one_frame},
		moveboxs={hurt_box},
	}

	return gk.charecter_push_state(char, move)
}
cyberpunk_state_jump_backward ::proc(char: ^gk.CharecterBase(Charecter)) -> gk.state_index {
	context.allocator = vmem.arena_allocator(&char.arena)
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	jump_backwards_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		char.jump_requested = true
		char.body.velocity.y = char.jump_height
		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.air_move_speed)
		if !char.p1_side do char.body.velocity.x = char.air_move_speed
	})
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},
		on_frame =jump_backwards_on_frame_index,
		 // todo change me
	}
	one_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {0},
		hitbox_list = {},

		check_exit = air_state_cancel_index, // todo change me
	}
	move := gk.State {
		name="jump back",
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		moveboxs={hurt_box},
		frames = {zero_frame, one_frame},
	}
	return gk.charecter_push_state(char, move)
}

cyberpunk_pattern_stand_neutral ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_crouch ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Down}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})
	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownBack}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})
	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownForward}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})

}
cyberpunk_pattern_forward ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_backward ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Up}},
		pritority   = 0,
		state_index = index,
		air_ok=false, // set to true to enable double jump
		air_only=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_forward ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_backward ::proc(char: ^gk.CharecterBase(Charecter),index:gk.state_index) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpBack}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	append(&char.patterns, pattern)
}





cyberpunk_add_punch_attacks :: proc(char:^gk.CharecterBase(Charecter)) {
    index := cyberpunk_add_stand_light(char)
    cyberpunk_pattern_stand_light(char,index)

    index = cyberpunk_add_crouch_light(char)
    cyberpunk_pattern_crouch_light_punch(char,index)

    index = cyberpunk_add_crouch_heavy(char)
    cyberpunk_pattern_crouch_heavy_punch(char,index)

    //need to add in air to patterns
    index = cyberpunk_add_jump_punch(char)
    log.debug(index)
    cyberpunk_pattern_jump_punch(char,index)
}

cyberpunk_add_stand_light :: proc (char:^gk.CharecterBase(Charecter)) -> int{
   	context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
           box = psy.box_init(
               {0, 0,0,0},
               {10,0, 5,0},
           ),
           hitKnockback = psy.vec2_init({1,5,0,0}),
           blockPushback = psy.vec2_init({12,0,0,0}),
	}
	hurt_box := gk.Hurt_box{
	    box=psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	move := gk.State {
		name="stand light attack",
		moveboxs = {hit_box,hurt_box},
		damage = 10,
		frames    = {},
		isAttack  = true,
		hitstun   = 25,
		blockstun = 10,
	}
	// 5 startup
	for i := 0; i < 4; i += 1 {
	append(&move.frames,
    	gk.Frame {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {1},
    		hitbox_list = {},

    		 // todo change me
    	})
	}
	//5 active
	for i := 0; i < 4; i += 1 {
		append(&move.frames,
		gk.Frame {
			frame_type = gk.FrameType.Active,
			//
			hurtbox_list = {1},
			hitbox_list = {0},

			check_exit = cancelable_on_hit_or_block_index, // todo change me
		})
	}
	//9 recovery
	for i := 0; i < 7; i += 1 {
		append(&move.frames,
		gk.Frame {
			frame_type = gk.FrameType.Recovery,
			//
			hurtbox_list = {1},
			hitbox_list = {},

			check_exit = cancelable_on_hit_or_block_index, // todo change me
		},)
	}
	append(&move.frames,
	gk.Frame {
		frame_type = gk.FrameType.Recovery,
		//
		hurtbox_list = {1},
		hitbox_list = {},

		check_exit = any_cancel_index, // todo change me
	})
	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_add_crouch_light::proc(char:^gk.CharecterBase(Charecter)) -> int{
    context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
           box = psy.box_init(
               {0, 0,0,0},
               {10,0, 5,0},
           ),
           hitKnockback = psy.vec2_init({-1,0,0,0}),
           blockPushback = psy.vec2_init({1,0,0,0}),
	}
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,5,0}),
	}
	move := gk.State {
		name="crouch light attack",
		moveboxs = {hit_box,hurt_box},
		damage = 10,
		air_ok=false,
		frames    = {},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	// 5 startup
	for i := 0; i < 4; i += 1 {
	append(&move.frames,
    	gk.Frame {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {1},
    		hitbox_list = {},

    		 // todo change me
    	})
	}
	//5 active
	for i := 0; i < 4; i += 1 {
		append(&move.frames,
		gk.Frame {
			frame_type = gk.FrameType.Active,
			//
			hurtbox_list = {1},
			hitbox_list = {0},

			check_exit = cancelable_on_hit_or_block_index, // todo change me
		})
	}
	//9 recovery
	for i := 0; i < 7; i += 1 {
		append(&move.frames,
		gk.Frame {
			frame_type = gk.FrameType.Recovery,
			//
			hurtbox_list = {1},
			hitbox_list = {},

			check_exit = cancelable_on_hit_or_block_index, // todo change me
		})
	}
	append(&move.frames,
	gk.Frame {
		frame_type = gk.FrameType.Recovery,
		//
		hurtbox_list = {1},
		hitbox_list = {},

		check_exit = any_cancel_index, // todo change me
	})
	append(&char.states, move)
	index := len(char.states)-1
	return index
}



cyberpunk_add_crouch_heavy::proc(char:^gk.CharecterBase(Charecter)) -> int{
    context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
           box = psy.box_init(
               {0, 0,0,0},
               {10,0, 5,0},
           ),
           hitKnockback = psy.vec2_init({-1,0,0,0}),
           blockPushback = psy.vec2_init({1,0,0,0}),
	}
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,5,0}),
	}
	move := gk.State {
		name="crouch light attack",
		moveboxs = {hit_box,hurt_box},
		damage = 10,
		air_ok=false,
		hard_knockdown=true,
		frames    = {},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	//add startup
	for i := 0; i < 14; i += 1 {
	    append(&move.frames,gk.Frame {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {1},
    		hitbox_list = {},

    		 // todo change me
    	},)
	}
	//add active
	for i := 0; i < 4; i += 1 {
	    append(&move.frames,gk.Frame {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {1},
			hitbox_list = {0},

			 // todo change me
		})
	}
	//add recovery
	for i := 0; i < 9; i += 1 {
	    append(&move.frames,gk.Frame {
			frame_type = gk.FrameType.Recovery,
			hurtbox_list = {1},
			hitbox_list = {},

			check_exit = any_cancel_index, // todo change me
		})
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}



cyberpunk_add_jump_punch :: proc(char:^gk.CharecterBase(Charecter)) -> int{
    context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
           box = psy.box_init(
               {0, 0,0,0},
               {10,0, 5,0},
           ),
           hitKnockback = psy.vec2_init({-1,0,0,0}),
           blockPushback = psy.vec2_init({1,0,0,0}),
	}
	hurt_box := gk.Hurt_box {
	    box=psy.box_init({0,0,0,0},{5,0,10,0}),
	}
	move := gk.State {
		name="jump light attack",
		moveboxs = {hit_box,hurt_box},
		damage = 10,
		air_ok=true,
		frames    = {
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {1},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {1},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {1},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {1},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {1},
				hitbox_list = {0},

				check_exit = cancelable_on_hit_or_block_index, // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {1},
				hitbox_list = {0},

				check_exit = cancelable_on_hit_or_block_index, // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {1},
				hitbox_list = {0},

				check_exit = cancelable_on_hit_or_block_index, // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {1},
				hitbox_list = {0},

				check_exit = cancelable_on_hit_or_block_index, // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {1},
				hitbox_list = {},

				check_exit = air_state_cancel_index, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}


cyberpunk_pattern_stand_light :: proc(char:^gk.CharecterBase(Charecter),index:int) {
    context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern("6l",index,1,false,false,context.allocator)
	pattern2 := tools.number_notation_to_pattern("5l",index,1,false,false,context.allocator)
	pattern3 := tools.number_notation_to_pattern("4l",index,1,false,false,context.allocator)
	// gk.Pattern {
	// 	inputs      = {gk.Input{dir = gk.Direction.Forward, attack = {gk.Button.Light,nil,nil,nil,nil}}},
	// 	pritority   = 1,
	// 	state_index = index,
	// }
	// pattern2 := gk.Pattern {
	// 	inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = {gk.Button.Light,nil,nil,nil,nil}}},
	// 	pritority   = 1,
	// 	state_index = index,
	// 	air_ok=false,
	// 	air_only=false,
	// }
	// pattern3 := gk.Pattern {
	// 	inputs      = {gk.Input{dir = gk.Direction.Back, attack = {gk.Button.Light,nil,nil,nil,nil}}},
	// 	pritority   = 1,
	// 	state_index = index,
	// 	air_ok=false,
	// 	air_only=false,
	// }
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}
cyberpunk_pattern_crouch_heavy_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern("3h",index,1,false,false,context.allocator)
	pattern2 := tools.number_notation_to_pattern("2h",index,1,false,false,context.allocator)
	pattern3 := tools.number_notation_to_pattern("1h",index,1,false,false,context.allocator)
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}
cyberpunk_pattern_crouch_light_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern("3l",index,0,false,false,context.allocator)
	pattern2 := tools.number_notation_to_pattern("2l",index,0,false,false,context.allocator)
	pattern3 := tools.number_notation_to_pattern("1l",index,0,false,false,context.allocator)
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}

// todo
cyberpunk_pattern_jump_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern("6m",index,1,true,true,context.allocator)
	pattern2 := tools.number_notation_to_pattern("5m",index,1,true,true,context.allocator)
	pattern3 := tools.number_notation_to_pattern("4m",index,1,true,true,context.allocator)
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}


cyberpunk_add_fireball :: proc(char: ^gk.CharecterBase(Charecter)) {
    light_entity_index := cyberpunk_entity_fireball_light(char)
    medium_fireball_entity_index := cyberpunk_entity_fireball_medium(char)

    cyber:= &char.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk)
    cyber.light_fireball_entity_index = light_entity_index
    cyber.med_fireball_entity_index = medium_fireball_entity_index

    index := cyberpunk_state_light_fireball(char)
    cyberpunk_pattern_light_fireball(char,index)


    index = cyberpunk_state_medium_fireball(char)
    cyberpunk_pattern_medium_fireball(char,index)
}



cyberpunk_state_light_fireball ::proc(char: ^gk.CharecterBase(Charecter)) -> int {
    context.allocator = vmem.arena_allocator(&char.arena)
    hurt_box := gk.Hurt_box {
        box = psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0}),
    }
    spawn_fireball_on_frame_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
  		log.debug("spawn fireball")
        budget := &char.serlized_state.charecter_info.budget
        cyber:= &char.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk)
        if budget^ > 0 {
            budget^ -= 20
            gk.activate_entity(char,cyber.light_fireball_entity_index,w) // activate fireball
        } else {
            // todo play no cost sound. Should we shorten recovery
            // how would we by using a flag in charecter info?
            // char.serlized_state.health -=20*2
        }
  		log.debug("gaming")
   	})
	move := gk.State {
		name="light fireball",
		moveboxs = {hurt_box},
		damage = 0,
		air_ok=true,
		frames    = {
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {},
				hitbox_list = {},
				on_frame = reset_velocity_index,
				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {0},
				hitbox_list = {},
				on_frame =  spawn_fireball_on_frame_index,
				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				 // todo change me
			},
			gk.Frame {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {0},
				hitbox_list = {},

				check_exit = air_state_cancel_index, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_medium_fireball ::proc(char: ^gk.CharecterBase(Charecter)) -> int {
    context.allocator = vmem.arena_allocator(&char.arena)
    fireball_onframe_index := gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
  		log.debug("spawn fireball")
        budget := &char.serlized_state.charecter_info.budget
        cyber:= &char.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk)
        if budget^ > 0 {
            budget^ -= 20
            gk.activate_entity(char,cyber.light_fireball_entity_index,w) // activate fireball
        } else {
            // todo play no cost sound. Should we shorten recovery
            // how would we by using a flag in charecter info?
            // char.serlized_state.health -=20*2
        }
  		log.debug("gaming")
   	})
    reset_velocity_index = gk.push_function(&char.hooks.onFrame,proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		char.body.velocity = {}
    })
    hurt_box := gk.Hurt_box {
        box = psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0}),
    }
	move := gk.State {
		name="medium fireball",
		moveboxs = {hurt_box},
		damage = 0,
		air_ok=true,
		frames    = {
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			hurtbox_list = {0},
    			hitbox_list = {},
    			on_frame =reset_velocity_index,
    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Startup,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Active,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},
    			on_frame =  fireball_onframe_index,
    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			 // todo change me
    		},
    		gk.Frame {
    			frame_type = gk.FrameType.Recovery,
    			//
    			hurtbox_list = {0},
    			hitbox_list = {},

    			check_exit = air_state_cancel_index, // todo change me
    		},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}


cyberpunk_pattern_light_fireball ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern("236l",index,2,true,false,context.allocator)
	pattern2 := tools.number_notation_to_pattern("2356l",index,2,true,false,context.allocator)
	pattern3 := tools.number_notation_to_pattern("2366l",index,2,true,false,context.allocator)
	pattern4 := tools.number_notation_to_pattern("2365l",index,2,true,false,context.allocator)
	pattern5 := tools.number_notation_to_pattern("23659l",index,2,true,false,context.allocator)
	pattern6 := tools.number_notation_to_pattern("236595l",index,2,true,false,context.allocator)
	pattern7 := tools.number_notation_to_pattern("2368l",index,2,true,false,context.allocator)
	pattern8 := tools.number_notation_to_pattern("23699l",index,2,true,false,context.allocator)

	//this could use some refinment
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
	append(&char.patterns, pattern4)
	append(&char.patterns, pattern5)
	append(&char.patterns, pattern6)
	append(&char.patterns, pattern7)
	append(&char.patterns, pattern8)
}

cyberpunk_pattern_medium_fireball ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := tools.number_notation_to_pattern(
	    "236m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	pattern_2 := tools.number_notation_to_pattern(
	    "2356m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	pattern_3 :=  tools.number_notation_to_pattern(
	    "2366m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	pattern_4 := tools.number_notation_to_pattern(
	    "2365m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	pattern_5 := tools.number_notation_to_pattern(
	    "23659m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	pattern_6 := tools.number_notation_to_pattern(
	    "236595m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	// gk.Pattern {
	// 	inputs      = {
	// 		gk.Input{dir = gk.Direction.Neutral, attack = {gk.Button.Medium,nil,nil,nil,nil}},
	// 		gk.Input{dir = gk.Direction.UpForward},
	// 		gk.Input{dir = gk.Direction.Neutral},
	// 		gk.Input{dir = gk.Direction.Forward},
	// 		gk.Input{dir = gk.Direction.DownForward},
	// 		gk.Input{dir = gk.Direction.Down},
	// 	},
	// 	pritority   = 2,
	// 	state_index = index,
	// 	air_ok = true,
	// }
	pattern_7 := tools.number_notation_to_pattern(
	    "2368m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	// gk.Pattern {
	// 	inputs      = {
	// 		gk.Input{dir = gk.Direction.Up, attack = {gk.Button.Medium,nil,nil,nil,nil}},
	// 		gk.Input{dir = gk.Direction.Forward},
	// 		gk.Input{dir = gk.Direction.DownForward},
	// 		gk.Input{dir = gk.Direction.Down},
	// 	},
	// 	pritority   = 2,
	// 	state_index = index,
	// 	air_ok = true,
	// }
	//this could use some refinment
	pattern_9 := tools.number_notation_to_pattern(
	    "23699m",
	    index,
	    2,
	    true,
	    false,
		vmem.arena_allocator(&char.arena),
	)
	// gk.Pattern {
	// 	inputs      = {
	// 		gk.Input{dir = gk.Direction.UpForward, attack = {gk.Button.Medium,nil,nil,nil,nil}},
	// 		gk.Input{dir = gk.Direction.UpForward},
	// 		gk.Input{dir = gk.Direction.Forward},
	// 		gk.Input{dir = gk.Direction.DownForward},
	// 		gk.Input{dir = gk.Direction.Down},
	// 	},
	// 	pritority   = 2,
	// 	state_index = index,
	// 	air_ok = true,
	// }
	append(&char.patterns, pattern)
	append(&char.patterns, pattern_2)
	append(&char.patterns, pattern_3)
	append(&char.patterns, pattern_4)
	append(&char.patterns, pattern_5)
	append(&char.patterns, pattern_6)
	append(&char.patterns, pattern_7)
	append(&char.patterns, pattern_9)
}

cyberpunk_entity_fireball_light ::proc(char: ^gk.CharecterBase($Charecter)) -> int{
   	context.allocator = vmem.arena_allocator(&char.arena)
    on_frame_index := gk.push_function(&char.hooks.onFrame,proc(charecter: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
        entity_index := charecter.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk).light_fireball_entity_index
        entity := &charecter.entity_pool[entity_index]
		if entity.charecter_ptr.p1_side do entity.body.velocity.x = psy.invert_fixed(entity.move_speed)
		if !entity.charecter_ptr.p1_side do entity.body.velocity.x = entity.move_speed
	})
	append(&char.entity_pool,gk.Entity(Charecter) {
		move_speed = psy.init_from_parts(4,0),
		states = {
			gk.State {
				damage = 10,
				hitstun = 16,
				blockstun = 32,
				hitstop = 10,
				moveboxs = {
					gk.Hit_box {
					    box = psy.box_init(
							[4]i16{0,0,0, 0},
							[4]i16{10,0,5,0},
						),
						hitKnockback = psy.vec2_init({1,0,0, 0}),
						blockPushback = psy.vec2_init({5,0,0,0}),
					},
					gk.Hurt_box {
					    box = psy.box_init([4]i16{0,0,0,0},[4]i16{5,0, 5,0}),
					},
				},
				frames= {
					gk.Frame {
						frame_type = gk.FrameType.Recovery,
						//
						hurtbox_list = {
							1,
						},
						hitbox_list= {0},
						on_frame = on_frame_index,
						 // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		on_hit=			   proc(self:^gk.Entity(Charecter),hit_ctx:gk.CheckHitResult,w:^gk.World(Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,w)
		},
		on_block=		   proc(self:^gk.Entity(Charecter),hit_ctx:gk.CheckHitResult,w:^gk.World(Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,w)
		},
		physcis_update=    proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		deactivate=        proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)) {},
	})
	log.debug(char.entity_pool)
	index := len(char.entity_pool)-1
	return index
}

cyberpunk_entity_fireball_medium ::proc(char: ^gk.CharecterBase($Charecter)) -> int{
   	context.allocator = vmem.arena_allocator(&char.arena)
    on_frame_index := gk.push_function(&char.hooks.onFrame,proc(charecter: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
        entity_index := charecter.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk).med_fireball_entity_index
        entity := &charecter.entity_pool[entity_index]
		if entity.charecter_ptr.p1_side do entity.body.velocity.x = psy.invert_fixed(entity.move_speed)
		if !entity.charecter_ptr.p1_side do entity.body.velocity.x = entity.move_speed
		entity.body.velocity.y = psy.invert_fixed(entity.move_speed)
	})
	append(&char.entity_pool,gk.Entity(Charecter) {
		move_speed = psy.init_from_parts(4,0),
		states = {
			gk.State {
				damage = 10,
				hitstun = 16,
				blockstun = 32,
				hitstop = 10,
				moveboxs = {
					gk.Hit_box {
					    box = psy.box_init(
							[4]i16{0,0,0, 0},
							[4]i16{10,0,5,0},
						),
						hitKnockback = psy.vec2_init({0,0,5, 0}),
						blockPushback = psy.vec2_init({5,0,0,0}),
					},
					gk.Hurt_box {
					    box = psy.box_init([4]i16{0,0,0,0},[4]i16{5,0, 5,0}),
					},
				},
				frames= {
					gk.Frame {
						frame_type = gk.FrameType.Recovery,
						//
						hurtbox_list = {1},
						hitbox_list= {0},
						on_frame = on_frame_index,
						 // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		on_hit=			   proc(self:^gk.Entity(Charecter),hit_ctx:gk.CheckHitResult,w:^gk.World(Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,w)
		},
		on_block=		   proc(self:^gk.Entity(Charecter),hit_ctx:gk.CheckHitResult,w:^gk.World(Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,w)
		},
		physcis_update=    proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		deactivate=        proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)) {},
	})
	log.debug(char.entity_pool)
	index := len(char.entity_pool)-1
	return index
}


//TODO
// medium is a downard angaled fireball that causes a ground bounce
// headvy you pick them up then shoot them for a wall bounce
