#+feature dynamic-literals
#+vet !unused !using-stmt
#+feature using-stmt

package game
// import rl "vendor:raylib"
import "core:log"
import gk "game_kernel"
import vmem "core:mem/virtual"
import psy "./physics"

create_generic_charecter :: proc() -> gk.CharecterBase {
   	charecter := gk.CharecterBase {
		health=200,
		body = psy.body_init({0, 10}),
		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2}),
		move_speed = psy.f64_to_fixed(7),
		air_drag = psy.f64_to_fixed(0.5),
		air_move_speed = psy.f64_to_fixed(15.0),
		jump_height = psy.f64_to_fixed(50.0),
		p1_side = true,
		hooks = {
            damage_formula = gk.default_dammage_formula,
            charecter_check_counterhit = gk.default_counterhit_check,
		},
	}
	return charecter
}

state_neutral ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)
	unfixed_box := psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}}
	fixed := psy.fix_box(unfixed_box)
	unfixed_2 := psy.unfix_box(fixed)
	zero_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(unfixed_box)},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.move_dir = Vec3{0, 0, 0}
			//todo if should we check if grounded?
			// we are going to have to change this
			char.body.velocity.x = psy.Fixed12_4 {}
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State(gk.CharecterBase) {
		name="neutral",
		frames = {zero_frame},
	}
	append(&char.states, move)
}
state_forward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State(gk.CharecterBase) {
		name="forward",
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	append(&char.states, move)
}


state_backward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
    		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
    		if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State(gk.CharecterBase) {
		name="backward",
		frames = {zero_frame},
	}

	append(&char.states, move)
}
state_jump ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	one_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	two_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase) {
		name="nutral jump",
		frames = {zero_frame, one_frame, two_frame},
	}

	append(&char.states, move)
}
state_jump_forward ::proc(char: ^gk.CharecterBase) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec364{1, 1, 0}
			if !char.p1_side do char.move_dir = Vec364{-1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase) {
		name="jump forward",
		frames = {zero_frame},
	}

	append(&char.states, move)
}
state_jump_backward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	one_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	two_frame := gk.Frame(CharecterBase) {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State(gk.CharecterBase) {
		name="jump back",
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame, two_frame},
	}
	append(&char.states, move)
}

pattern_neutral ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = Attack.None}},
		pritority   = 0,
		state_index = 0,
	}
	append(&char.patterns, pattern)
}
pattern_forward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = Attack.None}},
		pritority   = 0,
		state_index = 1,
	}
	append(&char.patterns, pattern)
}
pattern_backward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Back, attack = Attack.None}},
		pritority   = 0,
		state_index = 2,
	}
	append(&char.patterns, pattern)
}
pattern_jump ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Up, attack = Attack.None}},
		pritority   = 0,
		state_index = 3,
	}
	append(&char.patterns, pattern)
}
pattern_jump_forward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 4,
	}
	append(&char.patterns, pattern)
}
pattern_jump_backward ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := Pattern {
		inputs      = {Input{dir = Direction.UpBack, attack = Attack.None}},
		pritority   = 0,
		state_index = 5,
	}
	append(&char.patterns, pattern)
}


add_state_movement ::proc(char: ^gk.CharecterBase) {
	using gk
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




state_light_attack ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	hit_box := Hit_box {
        box = psy.fix_box(psy.UnfixedBox{
            position    = [2]f64{0, 0},
            extent      = [2]f64{10., 5.},
        }),
        hitKnockback = Vec264{-1, 0},
		blockPushback = Vec264{1,0},
	}
	move := gk.State(gk.CharecterBase) {
		name="light attack",
		hit_boxes = {hit_box},
		damage = 10,
		frames    = {
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
				},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {0},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = gk.free_cancel, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
}


pattern_light_attack ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = Direction.Forward, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern2 := gk.Pattern {
		inputs      = {gk.Input{dir = Direction.Neutral, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern3 := gk.Pattern {
		inputs      = {gk.Input{dir = Direction.Back, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}

add_state_light_attack ::proc(char: ^gk.CharecterBase) {
	using gk
	state_light_attack(char)
	pattern_light_attack(char)
}

state_light_fireball ::proc(char: ^gk.CharecterBase) {
    context.allocator = vmem.arena_allocator(&char.arena)

	using gk
	move := gk.State(gk.CharecterBase) {
		name="fireball",
		hit_boxes = {},
		damage = 0,
		frames    = {
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
					char.body.velocity = {}
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			Frame(gk.CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
					log.debug("spawn fireball")
					activate_entity(char,0,w) // activate fireball
					log.debug("gaming")
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
					log.debug("gaming2")
				},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
				check_exit = no_cancel, // todo change me
			},
			gk.Frame(CharecterBase) {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
				hitbox_list = {},
				on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {
				    log.debug("bruh fuck")
				},
				check_exit = gk.free_cancel, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
}


pattern_light_fireball ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {
			gk.Input{dir = Direction.Forward, attack = Attack.Light},
			gk.Input{dir = Direction.DownForward, attack = Attack.None},
			gk.Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_2 := gk.Pattern {
		inputs      = {
			gk.Input{dir = Direction.Forward, attack = Attack.Light},
			gk.Input{dir = Direction.Neutral, attack = Attack.None},
			gk.Input{dir = Direction.DownForward, attack = Attack.None},
			gk.Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_3 := gk.Pattern {
		inputs      = {
			gk.Input{dir = Direction.Forward, attack = Attack.Light},
			gk.Input{dir = Direction.Forward, attack = Attack.None},
			gk.Input{dir = Direction.DownForward, attack = Attack.None},
			gk.Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_4 := gk.Pattern {
		inputs      = {
			gk.Input{dir = Direction.Neutral, attack = Attack.Light},
			gk.Input{dir = Direction.Forward, attack = Attack.None},
			gk.Input{dir = Direction.DownForward, attack = Attack.None},
			gk.Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern_2)
	append(&char.patterns, pattern_3)
	append(&char.patterns, pattern_4)
}

entity_fireball ::proc(char: ^gk.CharecterBase) {
   	context.allocator = vmem.arena_allocator(&char.arena)

	append(&char.entity_pool,gk.Entity {
		move_speed = 4.0,
		states = {
			gk.State(gk.Entity) {
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
					gk.Frame(gk.Entity) {
						frame_type = gk.FrameType.Recovery,
						//I think inline allocations of dynamics is causing leaks
						hurtbox_list = {
							psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 5.}}),
						},
						hitbox_list= {0},
						on_frame = proc(enitity: ^gk.Entity,w:^gk.World) {
							if  enitity.charecter_ptr.p1_side do enitity.body.velocity.x = psy.f64_to_fixed(f64(-1 * enitity.move_speed))
							if !enitity.charecter_ptr.p1_side do enitity.body.velocity.x = psy.f64_to_fixed(f64(1 * enitity.move_speed))
						},
						check_exit = proc(char: ^gk.Entity, cancel_index: int) -> bool {
							return false
						}, // todo change me
					},
				},
			},
		},
		activate=  proc(self:^gk.Entity,charecter:^gk.CharecterBase,world:^gk.World){
			self.body.position = charecter.body.position
		}, // this runs onetime
		update=            proc(self:^gk.Entity,charecter:^gk.CharecterBase,world:^gk.World){},
		on_hit=			   proc(self:^gk.Entity,hit_ctx:gk.HitBoxCtx(gk.Entity)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		on_block=		   proc(self:^gk.Entity,hit_ctx:gk.HitBoxCtx(gk.Entity)){
			gk.deactivate_entity(self,self.charecter_ptr,hit_ctx.world)
		},
		physcis_update=    proc(self:^gk.Entity,charecter:^gk.CharecterBase,world:^gk.World){},
		deactivate=        proc(self:^gk.Entity,charecter:^gk.CharecterBase,world:^gk.World) {},
	})
	log.debug(char.entity_pool)
}

add_state_light_fireball ::proc(char: ^gk.CharecterBase) {
	state_light_fireball(char)
	pattern_light_fireball(char)
	entity_fireball(char)
}

add_state_stun::proc(char: ^gk.CharecterBase) {
	state_hit_stun(char)
	state_block_stun(char)
}

state_block_stun ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase) {
		name="blockstun",
		frames = {Frame(gk.CharecterBase) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
			hitbox_list = {},
			on_frame =proc(char: ^gk.CharecterBase,w:^gk.World) {},
			check_exit = exit_block_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.block_stun_index = index
}
state_hit_stun ::proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase) {
		name="hitstun",
		frames = {Frame(gk.CharecterBase) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase,w:^gk.World) {},
			check_exit = exit_hit_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	log.debug(index)
	char.hit_stun_index = index
}
