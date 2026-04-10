#+feature dynamic-literals
#+vet !unused !using-stmt
package characters

import gk "../game_kernel"
@(require) import "core:log"
import psy "../physics"
import vmem "core:mem/virtual"


//todo we should maybe rename this but charecter base is taken care of.
// so like idk what to name it
Charecter :: struct {
	budget:u64,
	charecter_spesific_data: union {
		Cyberpunk,
	},
}


make_air_state_cancel :: proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
	//todo make it so we only cansle jump state when we land or do a
	// jump normal/special
   	if char.in_air == false {
  		return true
   	}
   	return false
}


make_free_cancel_proc :: proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    return true
}


make_no_cancel_proc ::proc(char: gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    return false
}

exit_block_stun_proc :: proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    if char.block_stun_frames <= 0 {
        return true
    }
    return false
}


exit_hit_stun_proc ::  proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    if char.hit_stun_frames <= 0 {
        return true
    }
    return false
}

add_universal_states :: proc(char:^gk.CharecterBase(Charecter)) {
    add_hard_knockdown_state(char)
    add_soft_knockdown_state(char)
    add_state_block_stun(char)
    add_state_hit_stun(char)
}

//taken from strive
HARD_KNOCKDOWN_DURATION :: 55
add_hard_knockdown_state :: proc(char:^gk.CharecterBase(Charecter)) {
    context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			//todo if should we check if grounded?
			// we are going to have to change this
			char.body.velocity.x = psy.Fixed12_4 {}
		},
		check_exit = proc(char:^gk.CharecterBase(Charecter),proposed_state:int) -> bool{
		    return char.current_frame > HARD_KNOCKDOWN_DURATION
		},
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="hard_knockdown",
		frames = {zero_frame},
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.hard_knockdown_index = index
}
SOFT_KNOCKDOWN_DURATION :: 30
add_soft_knockdown_state :: proc(char:^gk.CharecterBase(Charecter)) {
    context.allocator = vmem.arena_allocator(&char.arena)
	zero_frame := gk.Frame(gk.CharecterBase(Charecter),Charecter) {
		frame_type = gk.FrameType.Active,
		hurtbox_list = {},
		hitbox_list = {},
		on_frame =proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {
			//todo if should we check if grounded?
			// we are going to have to change this
			char.body.velocity.x = psy.Fixed12_4 {}
		},
		check_exit = proc(char:^gk.CharecterBase(Charecter),proposed_state:int) -> bool{
		    return char.current_frame > SOFT_KNOCKDOWN_DURATION
		},
	}
	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="soft_knockdown",
		frames = {zero_frame},
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.soft_knockdown_index = index
}


add_state_hit_stun ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="hitstun",
		frames = {gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = exit_hit_stun_proc, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.hit_stun_index = index
}
add_state_block_stun ::proc(char: ^gk.CharecterBase(Charecter)) {
	context.allocator = vmem.arena_allocator(&char.arena)

	move := gk.State(gk.CharecterBase(Charecter),Charecter) {
		name="hitstun",
		frames = {gk.Frame(gk.CharecterBase(Charecter),Charecter) {
			frame_type = gk.FrameType.Active,
			hurtbox_list = {psy.box_init({0,0,0,0},{5,0,10,0})},
			hitbox_list = {},
			on_frame = proc(char: ^gk.CharecterBase(Charecter),w:^gk.World(Charecter)) {},
			check_exit = exit_block_stun_proc, // todo change me
		}},
		isAttack  = false,
	}
	append(&char.states, move)
	index := len(char.states)-1
	char.block_stun_index = index
}
