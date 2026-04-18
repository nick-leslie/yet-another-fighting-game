#+feature dynamic-literals
#+vet !unused !using-stmt
package characters

import gk "../game_kernel"
@(require) import "core:log"
import psy "../physics"
import vmem "core:mem/virtual"

Cyberpunk :: struct {
    light_fireball_entity_index:int,
    med_fireball_entity_index:int,
}


create_cyberpunk_charecter :: proc(pos:[4]i16,budget:i64) -> gk.CharecterBase(Charecter) {
    hooks := gk.CharecterHooks(Charecter) {
        damage_formula = gk.make_default_dammage_formula(Charecter),
        charecter_check_counterhit = gk.make_default_counterhit_check(Charecter),
	}
	log.debug(hooks)
   	charecter := gk.CharecterBase(Charecter) {
		health=200, // todo change me
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

	add_universal_states(&charecter)
	cyberpunk_add_state_movement(&charecter) // the nill is tmp
	cyberpunk_add_punch_attacks(&charecter)
	cyberpunk_add_fireball(&charecter)

	// cyberpunk_add_state_light_fireball(&charecter)
	return charecter
}


free_cancel :: proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
	return true
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

cyberpunk_state_stand_neutral ::proc(char: ^gk.CharecterBase(Charecter)) -> int{
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			//todo if should we check if grounded?
			// we are going to have to change this

			if char.in_air == false {
			    char.body.velocity.x = psy.Fixed12_4 {}
			}
		},
		check_exit = gk.make_free_cancel_proc(Charecter),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="neutral",
		frames = {zero_frame},
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_crouch_neutral ::proc(char: ^gk.CharecterBase(Charecter)) -> int{
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,5,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			//todo if should we check if grounded?
			// we are going to have to change this

			if char.in_air == false {
			    char.body.velocity.x = psy.Fixed12_4 {}
			}
		},
		check_exit = gk.make_free_cancel_proc(Charecter),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="neutral",
		frames = {zero_frame},
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_forward ::proc(char: ^gk.CharecterBase(Charecter)) -> int{
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.make_free_cancel_proc(Charecter),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="forward",
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	append(&char.states, move)
	index := len(char.states)-1
	return index
}


cyberpunk_state_backward ::proc(char: ^gk.CharecterBase(Charecter)) -> int{
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
    		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
    		if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.make_free_cancel_proc(Charecter),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="backward",
		frames = {zero_frame},
	}

	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_jump ::proc(char: ^gk.CharecterBase(Charecter)) -> int{
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		    char.jump_requested = true
			char.body.velocity.y = char.jump_height
		},
		check_exit = no_cancel, // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = air_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="nutral jump",
		frames = {zero_frame, one_frame},
	}

	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_jump_forward ::proc(char: ^gk.CharecterBase(Charecter)) -> int {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			char.jump_requested = true
			char.body.velocity.y = char.jump_height
			if char.p1_side do char.body.velocity.x = char.air_move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.air_move_speed)
		},
		check_exit = no_cancel, // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = air_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="jump forward",
		frames = {zero_frame,one_frame},
	}

	append(&char.states, move)
	index := len(char.states)-1
	return index
}
cyberpunk_state_jump_backward ::proc(char: ^gk.CharecterBase(Charecter)) -> int {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			char.jump_requested = true
			char.body.velocity.y = char.jump_height
			if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.air_move_speed)
			if !char.p1_side do char.body.velocity.x = char.air_move_speed
		},
		check_exit = no_cancel, // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {
		    psy.box_init({0,0,0,0},{5,0,10,0}),
		},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = air_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="jump back",
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame},
	}
	append(&char.states, move)
	index := len(char.states)-1
	return index
}

cyberpunk_pattern_stand_neutral ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_crouch ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Down, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})
	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownBack, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})
	append(&char.patterns,gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	})

}
cyberpunk_pattern_forward ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_backward ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Up, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false, // set to true to enable double jump
		air_only=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_forward ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_backward ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpBack, attack = gk.Button.None}},
		pritority   = 0,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	append(&char.patterns, pattern)
}





cyberpunk_add_punch_attacks :: proc(char:^gk.CharecterBase(Charecter)) {
    index := cyberpunk_add_stand_punch(char)
    cyberpunk_pattern_stand_punch(char,index)

    index = cyberpunk_add_crouch_light(char)
    cyberpunk_pattern_crouch_light_punch(char,index)

    index = cyberpunk_add_crouch_heavy(char)
    cyberpunk_pattern_crouch_heavy_punch(char,index)

    //need to add in air to patterns
    index = cyberpunk_add_jump_punch(char)
    log.debug(index)
    cyberpunk_pattern_jump_punch(char,index)
}

cyberpunk_add_stand_punch :: proc (char:^gk.CharecterBase(Charecter)) -> int{
   	context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
           box = psy.box_init(
               {0, 0,0,0},
               {10,0, 5,0},
           ),
           hitKnockback = psy.vec2_init({1,5,0,0}),
           blockPushback = psy.vec2_init({12,0,0,0}),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="stand light attack",
		hit_boxes = {hit_box},
		damage = 10,
		frames    = {},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	// 5 startup
	for i := 0; i < 4; i += 1 {
	append(&move.frames,
    	gk.Frame(gk.CharecterBase(Charecter),Charecter) {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
    		hitbox_list = {},
    		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
    		check_exit = no_cancel_accept_install, // todo change me
    	})
	}
	//5 active
	for i := 0; i < 4; i += 1 {
		append(&move.frames,
		gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Active,
			//
			hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
			hitbox_list = {0},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			},
			check_exit = no_cancel_accept_install, // todo change me
		})
	}
	//9 recovery
	for i := 0; i < 7; i += 1 {
		append(&move.frames,
		gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Recovery,
			//
			hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
			hitbox_list = {},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = no_cancel_accept_install, // todo change me
		},)
	}
	append(&move.frames,
	gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Recovery,
		//
		hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
		check_exit = free_cancel, // todo change me
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
	hurt_box := psy.box_init({0,0,0,0},{5,0,5,0})
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="crouch light attack",
		hit_boxes = {hit_box},
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
    	gk.Frame(gk.CharecterBase(Charecter),Charecter) {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {hurt_box},
    		hitbox_list = {},
    		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
    		check_exit = no_cancel_accept_install, // todo change me
    	})
	}
	//5 active
	for i := 0; i < 4; i += 1 {
		append(&move.frames,
		gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Active,
			//
			hurtbox_list = {hurt_box},
			hitbox_list = {0},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			},
			check_exit = no_cancel_accept_install, // todo change me
		})
	}
	//9 recovery
	for i := 0; i < 7; i += 1 {
		append(&move.frames,
		gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Recovery,
			//
			hurtbox_list = {hurt_box},
			hitbox_list = {},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = no_cancel_accept_install, // todo change me
		})
	}
	append(&move.frames,
	gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Recovery,
		//
		hurtbox_list = {hurt_box},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
		check_exit = free_cancel, // todo change me
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
	hurt_box := psy.box_init({0,0,0,0},{5,0,5,0})
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="crouch light attack",
		hit_boxes = {hit_box},
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
	    append(&move.frames,gk.Frame(gk.CharecterBase(Charecter),Charecter) {
    		frame_type = gk.FrameType.Startup,
    		hurtbox_list = {hurt_box},
    		hitbox_list = {},
    		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
    		check_exit = no_cancel, // todo change me
    	},)
	}
	//add active
	for i := 0; i < 4; i += 1 {
	    append(&move.frames,gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {hurt_box},
			hitbox_list = {0},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = no_cancel, // todo change me
		})
	}
	//add recovery
	for i := 0; i < 9; i += 1 {
	    append(&move.frames,gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Recovery,
			hurtbox_list = {hurt_box},
			hitbox_list = {},
			on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = gk.make_free_cancel_proc(Charecter), // todo change me
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
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="jump light attack",
		hit_boxes = {hit_box},
		damage = 10,
		air_ok=true,
		frames    = {
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = gk.make_free_cancel_proc(Charecter), // todo change me
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


cyberpunk_pattern_stand_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
    context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,

	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}
cyberpunk_pattern_crouch_heavy_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.Heavy}},
		pritority   = 1,
		state_index = index,
		air_ok=false,

	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Down, attack = gk.Button.Heavy}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownBack, attack = gk.Button.Heavy}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,

	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}
cyberpunk_pattern_crouch_light_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=false,

	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Down, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.DownBack, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=false,
		air_only=false,

	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}

// todo
cyberpunk_pattern_jump_punch :: proc(char:^gk.CharecterBase(Charecter),index:int) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=true,
		air_only=true,
	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=true,
		air_only=true,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Button.Light}},
		pritority   = 1,
		state_index = index,
		air_ok=true,
		air_only=true,

	}
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

	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="light fireball",
		hit_boxes = {},
		damage = 0,
		air_ok=true,
		frames    = {
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
					char.body.velocity = {}
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =  proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
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
               	},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
					log.debug("gaming2")
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
				    log.debug("bruh fuck")
				},
				check_exit = air_state_cancel, // todo change me
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

	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="medium fireball",
		hit_boxes = {},
		damage = 0,
		air_ok=true,
		frames    = {
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
					char.body.velocity = {}
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Startup,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Active,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =  proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
              		log.debug("spawn fireball")
                    cyber:= &char.serlized_state.charecter_info.charecter_spesific_data.(Cyberpunk)

              		gk.activate_entity(char,cyber.med_fireball_entity_index,w) // activate fireball
              		log.debug("gaming")
               	},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
					log.debug("gaming2")
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(gk.CharecterBase(Charecter),Charecter) {
				frame_type = gk.FrameType.Recovery,
				//
				hurtbox_list = {psy.box_init([4]i16{0,0,0, 0},[4]i16{5,0, 10,0})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
				    log.debug("bruh fuck")
				},
				check_exit = air_state_cancel, // todo change me
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

	pattern := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_2 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_3 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_4 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_5 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_6 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_7 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Up, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_8 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	//this could use some refinment
	pattern_9 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Light},
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern_2)
	append(&char.patterns, pattern_3)
	append(&char.patterns, pattern_4)
	append(&char.patterns, pattern_5)
	append(&char.patterns, pattern_6)
	append(&char.patterns, pattern_7)
	append(&char.patterns, pattern_8)
	append(&char.patterns, pattern_9)
}

cyberpunk_pattern_medium_fireball ::proc(char: ^gk.CharecterBase(Charecter),index:int) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_2 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_3 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_4 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_5 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_6 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_7 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Up, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	pattern_8 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	//this could use some refinment
	pattern_9 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.Medium},
			gk.Input{dir = gk.Direction.UpForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Button.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Button.None},
		},
		pritority   = 2,
		state_index = index,
		air_ok = true,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern_2)
	append(&char.patterns, pattern_3)
	append(&char.patterns, pattern_4)
	append(&char.patterns, pattern_5)
	append(&char.patterns, pattern_6)
	append(&char.patterns, pattern_7)
	append(&char.patterns, pattern_8)
	append(&char.patterns, pattern_9)
}

cyberpunk_entity_fireball_light ::proc(char: ^gk.CharecterBase($Charecter)) -> int{
   	context.allocator = vmem.arena_allocator(&char.arena)

	append(&char.entity_pool,gk.Entity(Charecter) {
		move_speed = psy.init_from_parts(4,0),
		states = {
			gk.State(gk.Entity(Charecter),Charecter) {
				damage = 10,
				hitstun = 16,
				blockstun = 32,
				hitstop = 10,
				hit_boxes = {
					gk.Hit_box {
					    box = psy.box_init(
							[4]i16{0,0,0, 0},
							[4]i16{10,0,5,0},
						),
						hitKnockback = psy.vec2_init({1,0,0, 0}),
						blockPushback = psy.vec2_init({5,0,0,0}),
					},
				},
				frames= {
					gk.Frame(gk.Entity(Charecter),Charecter) {
						frame_type = gk.FrameType.Recovery,
						//
						hurtbox_list = {
							psy.box_init([4]i16{0,0,0,0},[4]i16{5,0, 5,0}),
						},
						hitbox_list= {0},
						on_frame = proc(enitity: ^gk.Entity(Charecter),w:^gk.World(Charecter)) {
							if enitity.charecter_ptr.p1_side do enitity.body.velocity.x = psy.invert_fixed(enitity.move_speed)
							if !enitity.charecter_ptr.p1_side do enitity.body.velocity.x = enitity.move_speed
						},
						check_exit = proc(char: ^gk.Entity(Charecter), cancel_index: int) -> bool {
							return false
						}, // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		on_hit=			   proc(self:^gk.Entity(Charecter),hit_ctx:gk.HitBoxCtx(gk.Entity(Charecter),Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		on_block=		   proc(self:^gk.Entity(Charecter),hit_ctx:gk.HitBoxCtx(gk.Entity(Charecter),Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
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

	append(&char.entity_pool,gk.Entity(Charecter) {
		move_speed = psy.init_from_parts(4,0),
		states = {
			gk.State(gk.Entity(Charecter),Charecter) {
				damage = 10,
				hitstun = 16,
				blockstun = 32,
				hitstop = 10,
				hit_boxes = {
					gk.Hit_box {
					    box = psy.box_init(
							[4]i16{0,0,0, 0},
							[4]i16{10,0,5,0},
						),
						hitKnockback = psy.vec2_init({0,0,5, 0}),
						blockPushback = psy.vec2_init({5,0,0,0}),
					},
				},
				frames= {
					gk.Frame(gk.Entity(Charecter),Charecter) {
						frame_type = gk.FrameType.Recovery,
						//
						hurtbox_list = {
							psy.box_init([4]i16{0,0,0,0},[4]i16{5,0, 5,0}),
						},
						hitbox_list= {0},
						on_frame = proc(enitity: ^gk.Entity(Charecter),w:^gk.World(Charecter)) {
							if enitity.charecter_ptr.p1_side do enitity.body.velocity.x = psy.invert_fixed(enitity.move_speed)
							if !enitity.charecter_ptr.p1_side do enitity.body.velocity.x = enitity.move_speed
							enitity.body.velocity.y = psy.invert_fixed(enitity.move_speed)
						},
						check_exit = proc(char: ^gk.Entity(Charecter), cancel_index: int) -> bool {
							return false
						}, // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity(Charecter),charecter:^gk.CharecterBase(Charecter),world:^gk.World(Charecter)){},
		on_hit=			   proc(self:^gk.Entity(Charecter),hit_ctx:gk.HitBoxCtx(gk.Entity(Charecter),Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		on_block=		   proc(self:^gk.Entity(Charecter),hit_ctx:gk.HitBoxCtx(gk.Entity(Charecter),Charecter)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
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
