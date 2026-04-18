package game_kernel

@(require)import "core:log"
import psy "../physics"
State :: struct($T:typeid,$CU:typeid) {
	name:		   string,
	frames:        [dynamic]Frame(T,CU),
	hit_boxes: 	   [dynamic]Hit_box,
	hard_knockdown:bool,
	soft_knockdown:bool,
	// should all this be in a seprate struct
	canBlock:      bool,
	isAttack:      bool,
	air_ok:        bool,
	hitstun:       u32,
	hitstop:       u32,
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
	side_effect:   proc(self: T, world: World(CU),inRollback:bool),
	check_exit:    proc(self: ^T, frame: int) -> bool, // takes char pointer and proposed state
}

//for multi hits spawn a new hitbox
Hit_box :: struct {
    box:psy.FixedBox,
	hitKnockback:     psy.Vec2Fixed, // this is applied to other
	hitPushback:      psy.Vec2Fixed, // this is applied to self
	blockKnockback:   psy.Vec2Fixed,
	blockPushback:    psy.Vec2Fixed,
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
make_air_state_cancel :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
	//todo make it so we only cansle jump state when we land or do a
	// jump normal/special
        state,_ := charecter_get_current_state_frame(char)
    	if char.in_air == false || state.air_ok == true {
    		return true
    	}
    	// assert(false,"not implmented")
    	return false
    }
}


make_free_cancel_proc :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
        return true
    }
}


make_no_cancel_proc :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
        return false
    }
}


make_on_hit_or_block_cancel_proc :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
        return false
    }
}
make_exit_block_stun_proc :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
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

make_exit_hit_stun_proc :: proc($T: typeid) -> proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
    return proc(char: ^CharecterBase(T), cancel_index: int) -> bool {
        log.debug(char.hit_stun_frames)
        if char.hit_stun_frames <= 0 {
            return true
        }
        return false
    }
}
