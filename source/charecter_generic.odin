#+feature dynamic-literals
#+vet !unused !using-stmt

package game
// import rl "vendor:raylib"
import "core:log"
import gk "game_kernel"
import vmem "core:mem/virtual"
import psy "./physics"



TestCharecterData :: struct {

}

create_generic_charecter :: proc($CU:typeid,pos:[4]i16,p1_side:bool) -> gk.CharecterBase(CU) {
    hooks := gk.CharecterHooks(CU) {
              damage_formula = gk.make_default_dammage_formula(CU),
              charecter_check_counterhit = gk.make_default_counterhit_check(CU),
	}
	log.debug(hooks)
   	charecter := gk.CharecterBase(Charecters) {
		health=200,
		body = psy.body_init(pos),
		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2,0, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2,0}),
		move_speed = psy.init_from_parts(7,0),
		air_drag =psy.init_from_parts(0,5),
		air_move_speed = psy.init_from_parts(15,0),
		jump_height = psy.init_from_parts(-10,0),
		p1_side = p1_side,
		hooks = hooks,
	}
	gk.initilize_charecter_memory(&charecter)
	add_state_movement(&charecter) // the nill is tmp
	add_state_light_attack(&charecter)
	add_state_light_fireball(&charecter)
	return charecter
}

free_cancel :: proc(char: ^gk.CharecterBase($CU), cancel_index: int) -> bool {
	return true
}

state_neutral ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	unfixed_box := psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}}
	fixed := psy.fix_box(unfixed_box)
	unfixed_2 := psy.unfix_box(fixed)
	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(unfixed_box)},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
			//todo if should we check if grounded?
			// we are going to have to change this
			char.body.velocity.x = psy.Fixed12_4 {}
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(CU)),
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="neutral",
		frames = {zero_frame},
	}
	append(&char.states, move)
}
state_forward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(CU)),
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="forward",
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	append(&char.states, move)
}


state_backward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
    		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
    		if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(CU)),
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="backward",
		frames = {zero_frame},
	}

	append(&char.states, move)
}
state_jump ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
		    char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(CU)), // todo change me
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="nutral jump",
		frames = {zero_frame, one_frame},
	}

	append(&char.states, move)
}
state_jump_forward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
			char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(CU)), // todo change me
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="jump forward",
		frames = {zero_frame,one_frame},
	}

	append(&char.states, move)
}
state_jump_backward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
			char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
			if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
			if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(CU),CU) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(CU)), // todo change me
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="jump back",
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame},
	}
	append(&char.states, move)
}

pattern_neutral ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 0,
	}
	append(&char.patterns, pattern)
}
pattern_forward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 1,
	}
	append(&char.patterns, pattern)
}
pattern_backward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 2,
	}
	append(&char.patterns, pattern)
}
pattern_jump ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Up, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 3,
	}
	append(&char.patterns, pattern)
}
pattern_jump_forward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 4,
	}
	append(&char.patterns, pattern)
}
pattern_jump_backward ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpBack, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 5,
	}
	append(&char.patterns, pattern)
}


add_state_movement ::proc(char: ^gk.CharecterBase($CU)) {
	log.debug("in add movement")
	state_neutral(char)
	state_forward(char)
	state_backward(char)
	state_jump(char)
	state_jump_forward(char)
	state_jump_backward(char)
	log.debug("done adding movement")

	//add the move patterns
	pattern_neutral(char)
	pattern_forward(char)
	pattern_backward(char)
	pattern_jump(char)
	pattern_jump_forward(char)
	pattern_jump_backward(char)
	log.debug("done adding patterns")
}




state_light_attack ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := gk.Hit_box {
        box = psy.fix_box(psy.UnfixedBox{
            position    = [2]f64{0, 0},
            extent      = [2]f64{10., 5.},
        }),
        hitKnockback = Vec264{-1, 0},
		blockPushback = Vec264{1,0},
	}
	move := gk.State(gk.CharecterBase(CU),CU) {
		name="light attack",
		hit_boxes = {hit_box},
		damage = 10,
		frames    = {
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
				},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
}


pattern_light_attack ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}

add_state_light_attack ::proc(char: ^gk.CharecterBase($CU)) {
	state_light_attack(char)
	pattern_light_attack(char)
}

state_light_fireball ::proc(char: ^gk.CharecterBase($CU)) {
    context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase(CU),CU) {
		name="fireball",
		hit_boxes = {},
		damage = 0,
		frames    = {
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
					char.body.velocity = {}
				},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
				},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
					log.debug("spawn fireball")
					gk.activate_entity(char,0,w) // activate fireball
					log.debug("gaming")
				},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
					log.debug("gaming2")
				},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {},
				check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
			gk.Frame(gk.CharecterBase(CU),CU) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase(CU),w:^gk.World(CU)) {
				    log.debug("bruh fuck")
				},
				check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(CU)), // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
}


pattern_light_fireball ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.Light},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_2 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.Light},
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_3 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_4 := gk.Pattern {
		inputs      = {
			gk.Input{dir = gk.Direction.Neutral, attack = gk.Attack.Light},
			gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.DownForward, attack = gk.Attack.None},
			gk.Input{dir = gk.Direction.Down, attack = gk.Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern_2)
	append(&char.patterns, pattern_3)
	append(&char.patterns, pattern_4)
}

entity_fireball ::proc(char: ^gk.CharecterBase($CU)) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	append(&char.entity_pool,gk.Entity(CU) {
		move_speed = psy.init_from_parts(4,0),
		states = {
			gk.State(gk.Entity(CU),CU) {
				damage = 10,
				hitstun = 32,
				blockstun = 64,
				hit_boxes = {
					gk.Hit_box {
					    box = psy.fix_box(psy.UnfixedBox{
							position    = [2]f64{0, 0},
							extent      = [2]f64{10., 5.},
						}),
						hitKnockback = Vec264{-5, 0},
						blockPushback = Vec264{5,0},
					},
				},
				frames= {
					gk.Frame(gk.Entity(CU),CU) {
						frame_type = gk.FrameType.Recovery,
						//I think inline allocations of dynamics is causing leaks
						hurtbox_list = {
							psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 5.}}),
						},
						hitbox_list= {0},
						on_frame = proc(enitity: ^gk.Entity(CU),w:^gk.World(CU)) {
							if enitity.charecter_ptr.p1_side do enitity.body.velocity.x = psy.invert_fixed(enitity.move_speed)
							if !enitity.charecter_ptr.p1_side do enitity.body.velocity.x = enitity.move_speed
						},
						check_exit = proc(char: ^gk.Entity(CU), cancel_index: int) -> bool {
							return false
						}, // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity(CU),charecter:^gk.CharecterBase(CU),world:^gk.World(CU)){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity(CU),charecter:^gk.CharecterBase(CU),world:^gk.World(CU)){},
		on_hit=			   proc(self:^gk.Entity(CU),hit_ctx:gk.HitBoxCtx(gk.Entity(CU),CU)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		on_block=		   proc(self:^gk.Entity(CU),hit_ctx:gk.HitBoxCtx(gk.Entity(CU),CU)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		physcis_update=    proc(self:^gk.Entity(CU),charecter:^gk.CharecterBase(CU),world:^gk.World(CU)){},
		deactivate=        proc(self:^gk.Entity(CU),charecter:^gk.CharecterBase(CU),world:^gk.World(CU)) {},
	})
	log.debug(char.entity_pool)
}

add_state_light_fireball ::proc(char: ^gk.CharecterBase($CU)) {
	state_light_fireball(char)
	pattern_light_fireball(char)
	entity_fireball(char)
}

add_state_stun::proc(char: ^gk.CharecterBase($CU)) {
	state_hit_stun(char)
	state_block_stun(char)
}

state_block_stun ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase(CU),CU) {
		name="blockstun",
		frames = {gk.Frame(gk.CharecterBase(CU),CU) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
			hitbox_list = {},
			on_frame =proc(char: ^gk.CharecterBase($CU),w:^gk.World(CU)) {},
			check_exit = gk.exit_block_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.block_stun_index = index
}
state_hit_stun ::proc(char: ^gk.CharecterBase($CU)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase(CU),CU) {
		name="hitstun",
		frames = {gk.Frame(gk.CharecterBase(CU),CU) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase,w:^gk.World(CU)) {},
			check_exit = gk.exit_hit_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	log.debug(index)
	char.hit_stun_index = index
}
