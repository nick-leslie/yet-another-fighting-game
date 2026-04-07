#+feature dynamic-literals
#+vet !unused !using-stmt
package characters

import gk "../game_kernel"
@(require) import "core:log"
import psy "../physics"
import vmem "core:mem/virtual"

Cyberpunk :: struct {

}


create_cyberpunk_charecter :: proc(pos:[4]i16,budget:u64) -> gk.CharecterBase(Charecter) {
	 hooks := gk.CharecterHooks(Charecter) {
        damage_formula = gk.make_default_dammage_formula(Charecter),
        charecter_check_counterhit = gk.make_default_counterhit_check(Charecter),
	}
	log.debug(hooks)
   	charecter := gk.CharecterBase(Charecter) {
		health=200, // todo change me
		body = psy.body_init(pos),
		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2,0, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2,0}),
		move_speed = psy.init_from_parts(7,0),
		air_drag =psy.init_from_parts(0,5),
		air_move_speed = psy.init_from_parts(15,0),
		jump_height = psy.init_from_parts(-10,0),
		p1_side = true,
		hooks = hooks,
		serlized_state = {
			charecter_info=Charecter {
				budget=budget,
				charecter_spesific_data = Cyberpunk {
				},
			},
		},
	}
	gk.initilize_charecter_memory(&charecter)
	cyberpunk_add_state_movement(&charecter) // the nill is tmp
	// add_state_light_attack(&charecter)
	// cyberpunk_add_state_light_fireball(&charecter)
	return charecter
}


free_cancel :: proc(char: ^gk.CharecterBase($Charecter), cancel_index: int) -> bool {
	return true
}

cyberpunk_state_neutral ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	unfixed_box := psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}}
	fixed := psy.fix_box(unfixed_box)
	unfixed_2 := psy.unfix_box(fixed)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(unfixed_box)},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			//todo if should we check if grounded?
			// we are going to have to change this
			char.body.velocity.x = psy.Fixed12_4 {}
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(Charecter)),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="neutral",
		frames = {zero_frame},
	}
	append(&char.states, move)
}
cyberpunk_state_forward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(Charecter)),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="forward",
		frames = {zero_frame},
	}
	log.debug("in setting up physics")
	append(&char.states, move)
}


cyberpunk_state_backward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
    		if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
    		if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.make_free_cancel_proc(^gk.CharecterBase(Charecter)),
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="backward",
		frames = {zero_frame},
	}

	append(&char.states, move)
}
cyberpunk_state_jump ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		    char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(Charecter)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(Charecter)), // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="nutral jump",
		frames = {zero_frame, one_frame},
	}

	append(&char.states, move)
}
cyberpunk_state_jump_forward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
			if char.p1_side do char.body.velocity.x = char.move_speed
			if !char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(Charecter)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(Charecter)), // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="jump forward",
		frames = {zero_frame,one_frame},
	}

	append(&char.states, move)
}
cyberpunk_state_jump_backward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			char.jump_requested = true
			char.body.velocity.y = psy.invert_fixed(char.jump_height)
			if char.p1_side do char.body.velocity.x = psy.invert_fixed(char.move_speed)
			if !char.p1_side do char.body.velocity.x = char.move_speed
		},
		check_exit = gk.make_no_cancel_proc(^gk.CharecterBase(Charecter)), // todo change me
	}
	one_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {psy.fix_box(psy.UnfixedBox{position = [2]f64{0, 0}, extent = [2]f64{5., 10.}})},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
		},
		check_exit = gk.make_air_state_cancel(gk.CharecterBase(Charecter)), // todo change me
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="jump back",
		// model_ptr=model_prt,
		// animation_ptr=animation_ptr,
		frames = {zero_frame, one_frame},
	}
	append(&char.states, move)
}

cyberpunk_pattern_neutral ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Neutral, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 0,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_forward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Forward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 1,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_backward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Back, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 2,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.Up, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 3,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_forward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpForward, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 4,
	}
	append(&char.patterns, pattern)
}
cyberpunk_pattern_jump_backward ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	pattern := gk.Pattern {
		inputs      = {gk.Input{dir = gk.Direction.UpBack, attack = gk.Attack.None}},
		pritority   = 0,
		state_index = 5,
	}
	append(&char.patterns, pattern)
}


cyberpunk_add_state_movement ::proc(char: ^gk.CharecterBase(Charecter)) {
	log.debug("in add movement")
	cyberpunk_state_neutral(char)
	cyberpunk_state_forward(char)
	cyberpunk_state_backward(char)
	cyberpunk_state_jump(char)
	cyberpunk_state_jump_forward(char)
	cyberpunk_state_jump_backward(char)
	log.debug("done adding movement")

	//add the move patterns
	cyberpunk_pattern_neutral(char)
	cyberpunk_pattern_forward(char)
	cyberpunk_pattern_backward(char)
	cyberpunk_pattern_jump(char)
	cyberpunk_pattern_jump_forward(char)
	cyberpunk_pattern_jump_backward(char)
	log.debug("done adding patterns")
}
