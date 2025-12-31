#+feature dynamic-literals
package game
// import rl "vendor:raylib"
import "core:log"




state_neutral :: proc(char: ^Charecter) {

	zero_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.move_dir = Vec3{0, 0, 0}
		},
		check_exit = free_cancel,
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}
	setup_move_bodys(&move)
	append(&char.states, move)
}
state_forward :: proc(char: ^Charecter) {

	zero_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			if char.p1_side do char.move_dir = Vec3{1, 0, 0}
			if !char.p1_side do char.move_dir = Vec3{-1, 0, 0}
		},
		check_exit = free_cancel,
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	setup_move_bodys(&move)
	log.debugf("%x", &char.states)
	append(&char.states, move)
}


state_backward :: proc(char: ^Charecter) {
	zero_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			if char.p1_side do char.move_dir = Vec3{-1, 0, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 0, 0}
		},
		check_exit = free_cancel,
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}

	setup_move_bodys(&move)
	append(&char.states, move)
}
state_jump :: proc(char: ^Charecter) {
	zero_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = jump_state_cancel, // todo change me
	}
	one_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.jump_requested = true
			log.debug("are you running again")
			char.move_dir = Vec3{0, 1, 0}
		},
		check_exit = jump_state_cancel, // todo change me
	}
	two_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
		},
		check_exit = jump_state_cancel, // todo change me
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame, two_frame},
	}

	setup_move_bodys(&move)
	append(&char.states, move)
}
state_jump_forward :: proc(char: ^Charecter) {
	zero_frame := Frame {
		frame_type = FrameType.Active,
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{-1, 1, 0}
		},
		check_exit = jump_state_cancel, // todo change me
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame},
	}

	setup_move_bodys(&move)
	append(&char.states, move)
}
state_jump_backward :: proc(char: ^Charecter) {
	zero_frame := Frame {
		frame_type = FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0.}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = jump_state_cancel, // todo change me
	}
	one_frame := Frame {
		frame_type = FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
			char.jump_requested = true
			if char.p1_side do char.move_dir = Vec3{-1, 1, 0}
			if !char.p1_side do char.move_dir = Vec3{1, 1, 0}
		},
		check_exit = jump_state_cancel, // todo change me
	}
	two_frame := Frame {
		frame_type = FrameType.Active,
		//I think inline allocations of dynamics is causing leaks
		hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
		hitbox_list = {},
		on_frame = proc(char: ^Charecter) {
		},
		check_exit = jump_state_cancel, // todo change me
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame, two_frame},
	}
	setup_move_bodys(&move)
	append(&char.states, move)
}

pattern_neutral :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = Attack.None}},
		pritority   = 0,
		state_index = 0,
	}
	append(&char.patterns, pattern)
}
pattern_forward :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = Attack.None}},
		pritority   = 0,
		state_index = 1,
	}
	append(&char.patterns, pattern)
}
pattern_backward :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.Back, attack = Attack.None}},
		pritority   = 0,
		state_index = 2,
	}
	append(&char.patterns, pattern)
}
pattern_jump :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.Up, attack = Attack.None}},
		pritority   = 0,
		state_index = 3,
	}
	append(&char.patterns, pattern)
}
pattern_jump_forward :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.UpForward, attack = Attack.None}},
		pritority   = 0,
		state_index = 4,
	}
	append(&char.patterns, pattern)
}
pattern_jump_backward :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.UpBack, attack = Attack.None}},
		pritority   = 0,
		state_index = 5,
	}
	append(&char.patterns, pattern)
}


add_state_movement :: proc(char: ^Charecter) {
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




state_light_attack :: proc(char: ^Charecter) {
	hit_box := Hit_box {
		position    = Vec3{0, 0, 0},
		extent      = Vec3{10., 5., 10.},
		hitPushback = Vec3{-10, 0, 0},
	}
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames    = {
			Frame {
				frame_type = FrameType.Startup,
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Startup,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {hit_box},
				on_frame = proc(char: ^Charecter) {
				},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {hit_box},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {hit_box},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Active,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {hit_box},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = no_cancel, // todo change me
			},
			Frame {
				frame_type = FrameType.Recovery,
				//I think inline allocations of dynamics is causing leaks
				hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 10.}}},
				hitbox_list = {},
				on_frame = proc(char: ^Charecter) {},
				check_exit = free_cancel, // todo change me
			},
		},
		isAttack  = true,
		hitstun   = 15,
		blockstun = 10,
	}
	setup_move_bodys(&move)
	append(&char.states, move)
}


pattern_light_attack :: proc(char: ^Charecter) {
	pattern := Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern2 := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern3 := Pattern {
		inputs      = {Input{dir = Direction.Back, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	append(&char.patterns, pattern)
	append(&char.patterns, pattern2)
	append(&char.patterns, pattern3)
}

add_state_light_attack :: proc(char: ^Charecter) {
	state_light_attack(char)
	pattern_light_attack(char)
}


add_state_stun::proc(char: ^Charecter) {
	state_hit_stun(char)
	state_block_stun(char)
}

state_block_stun :: proc(char: ^Charecter) {
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {Frame {
			frame_type = FrameType.Active,
			hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
			hitbox_list = {},
			on_frame = proc(char: ^Charecter) {
				char.block_stun_frames-=1
			},
			check_exit = exit_block_stun, // todo change me
		}},
		isAttack  = false,
	}
	setup_move_bodys(&move)
	append(&char.states, move)
	index := len(char.states)-1
	char.block_stun_index = index
}
state_hit_stun :: proc(char: ^Charecter) {
	move := State {
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {Frame {
			frame_type = FrameType.Active,
			hurtbox_list = {Hurt_box{position = Vec3{0, 0, 0}, extent = Vec3{5., 10., 0.}}},
			hitbox_list = {},
			on_frame = proc(char: ^Charecter) {
				char.hit_stun_frames-=1
			},
			check_exit = exit_hit_stun, // todo change me
		}},
		isAttack  = false,
	}
	setup_move_bodys(&move)
	append(&char.states, move)
	index := len(char.states)-1
	log.debug(index)
	char.hit_stun_index = index
}
