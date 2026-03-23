package game_kernel

@(require)import "core:log"
import psy "../physics"
State :: struct($T:typeid,$CU:typeid) {
	name:		   string,
	frames:        [dynamic]Frame(T,CU),
	hit_boxes: 	   [dynamic]Hit_box,
	// should all this be in a seprate struct
	canBlock:      bool,
	isAttack:      bool,
	hitstun:       u32,
	blockstun:     u32,
	damage:        u32,
}
//this is cringe see if we can fix
Frame :: struct($T:typeid,$CU:typeid) {
	frame_type:    FrameType,
	cancel_states: [dynamic]int,
	hurtbox_list:  [dynamic]psy.FixedBox, // width height extent will be static we may want to make it an index
	hitbox_list:   [dynamic]int, // index into the hit box array of the state
	on_frame:      proc(self: ^T,world:^World(CU)),
	check_exit:    proc(self: ^T, frame: int) -> bool, // takes char pointer and proposed state
}

//for multi hits spawn a new hitbox
Hit_box :: struct {
    box:psy.FixedBox,
	hitKnockback:     Vec2, // this is applied to other
	hitPushback:      Vec2, // this is applied to self
	blockKnockback:   Vec2,
	blockPushback:    Vec2,
	attackDir:        AttackDir,
	// todo properties
}


FrameType :: enum {
	Startup,
	Active,
	Recovery,
}



AttackDir :: enum {
	Mid,
	High,
	Low,
}



delete_state :: proc(move: ^State) {
	for &frame in move.frames {
		delete(frame.hitbox_list)
		delete(frame.hurtbox_list)
		delete(frame.cancel_states)
	}
	delete(move.hit_boxes)
	delete(move.frames)
	delete(move.hurtbox_bodys)
}

check_cancel_options :: proc(char: ^CharecterBase($CU), cancel_index: int) -> bool {
	state := char.states[char.current_state]
	frame := state.frames[char.current_frame]
	if len(frame.cancel_states) == 0 {
		return true
	}
	for &cancel_option in frame.cancel_states {
		if cancel_option == cancel_index {
			return true
		}
	}
	return false
}


jump_state_cancel :: proc(char: ^CharecterBase($CU), cancel_index: int) -> bool {
	//todo make it so we only cansle jump state when we land or do a
	// jump normal/special

	if char.in_air == false {
		return true
	}
	// assert(false,"not implmented")
	return false
}

make_free_cancel_proc :: proc($T: typeid) -> proc(char: T, cancel_index: int) -> bool {
    return proc(char: T, cancel_index: int) -> bool {
        return true
    }
}


make_no_cancel_proc :: proc($T: typeid) -> proc(char: T, cancel_index: int) -> bool {
    return proc(char: T, cancel_index: int) -> bool {
        return false
    }
}

make_exit_block_stun_proc :: proc($T: typeid) -> proc(char: T, cancel_index: int) -> bool {
    return proc(char: T, cancel_index: int) -> bool {
        if char.block_stun_frames <= 0 {
            return true
        }
        return false
    }
}


make_on_hit_stun_proc :: proc($T: typeid) -> proc(char: T) {
    return proc(char: T) {
        char.hit_stun_frames -= 1
    }
}

make_on_block_stun_proc :: proc($T: typeid) -> proc(char: T) {
    return proc(char: T) {
        char.block_stun_frames -= 1
    }
}

make_exit_hit_stun_proc :: proc($T: typeid) -> proc(char: T, cancel_index: int) -> bool {
    return proc(char: T, cancel_index: int) -> bool {
        log.debug(char.hit_stun_frames)
        if char.hit_stun_frames <= 0 {
            return true
        }
        return false
    }
}
