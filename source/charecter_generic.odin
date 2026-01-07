#+feature dynamic-literals
#+vet !unused !using-stmt

package game
// import rl "vendor:raylib"
import "core:log"
import gk "game_kernel"
import vmem "core:mem/virtual"



state_neutral :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.move_dir = Vec3{0, 0, 0}
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}
	append(&char.states, move)
}
state_forward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			if char.p1_side do char.move_dir = Vec3{1, 0, 0}
			if !char.p1_side do char.move_dir = Vec3{-1, 0, 0}
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	append(&char.states, move)
}


state_backward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			if char.p1_side do char.move_dir = Vec3{-1, 0, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 0, 0}
		},
		check_exit = gk.free_cancel,
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}

	append(&char.states, move)
}
state_jump :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)
	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	one_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	two_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame, two_frame},
	}

	append(&char.states, move)
}
state_jump_forward :: proc(char: ^gk.CharecterBase) {
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{-1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}

	append(&char.states, move)
}
state_jump_backward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	zero_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0.}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	one_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	two_frame := gk.Frame {
		frame_type = gk.FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^gk.CharecterBase) {
		},
		check_exit = gk.jump_state_cancel, // todo change me
	}
	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame, two_frame},
	}
	append(&char.states, move)
}

pattern_neutral :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = Attack.None}},
		pritority   = 0,
		state_index = 0,
	}
	append(&char.patterns, pattern)
}
pattern_forward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = Attack.None}},
		pritority   = 0,
		state_index = 1,
	}
	append(&char.patterns, pattern)
}
pattern_backward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Back, attack = Attack.None}},
		pritority   = 0,
		state_index = 2,
	}
	append(&char.patterns, pattern)
}
pattern_jump :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := gk.Pattern {
		inputs      = {Input{dir = Direction.Up, attack = Attack.None}},
		pritority   = 0,
		state_index = 3,
	}
	append(&char.patterns, pattern)
}
pattern_jump_forward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 4,
	}
	append(&char.patterns, pattern)
}
pattern_jump_backward :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	pattern := Pattern {
		inputs      = {Input{dir = Direction.UpBack, attack = Attack.None}},
		pritority   = 0,
		state_index = 5,
	}
	append(&char.patterns, pattern)
}


add_state_movement :: proc(char: ^gk.CharecterBase) {
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




state_light_attack :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	hit_box := Hit_box {
		position    = Vec3{0, 0, 0},
		extent      = Vec3{10., 5., 10.},
		hitPushback = Vec3{-10, 0, 0},
	}
	move := gk.State {
		hit_boxes = {hit_box},
		frames    = {
			Frame {
				frame_type = gk.FrameType.Startup,
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {0},
				on_frame = proc(char: ^gk.CharecterBase) {
				},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {0},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {0},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {0},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = gk.FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^gk.CharecterBase) {},
				check_exit = gk.free_cancel, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	append(&char.states, move)
}


pattern_light_attack :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

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

add_state_light_attack :: proc(char: ^gk.CharecterBase) {
	using gk
	state_light_attack(char)
	pattern_light_attack(char)
}


add_state_stun::proc(char: ^gk.CharecterBase) {
	state_hit_stun(char)
	state_block_stun(char)
}

state_block_stun :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {Frame {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase) {},
			check_exit = exit_block_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.block_stun_index = index
}
state_hit_stun :: proc(char: ^gk.CharecterBase) {
	using gk
	context.allocator = vmem.arena_allocator(&char.charecter_arena)

	move := gk.State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {Frame {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {gk.Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase) {},
			check_exit = exit_hit_stun, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	log.debug(index)
	char.hit_stun_index = index
}
