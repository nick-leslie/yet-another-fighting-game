package game_kernel

@(require)import "core:log"
import psy "../physics"
State :: struct {
   	name:		   string,
	moveboxs:      [dynamic]MoveBox,
    state_type:    StateType,
	hard_knockdown:bool,
	soft_knockdown:bool,
	// should all this be in a seprate struct
	canBlock:      bool,
	isAttack:      bool,
	air_ok:        bool,
	//this is the techwindow of the throw
	tech_window:   u32,
	damage:        u32,
	blockstun:     u8,
	hitstun:       u8,
	hitstop:       u8,
	// reaction_index:u8, we may want this
	block_cancelable:bool,
	frames:        [dynamic]Frame,
}


//used for determenting if we should use throw detection or hit detection
StateType :: enum{
    Attack,
    Throw,
    //used for hitstun or when in a throw
    HitReaction,
    ThrowReaction,
}


//this is cringe see if we can fix
Frame :: struct {
   	frame_type:    FrameType,
    on_hit: Maybe(int),
    on_block:Maybe(int), // should these be distinct
    on_frame:Maybe(int),
    check_exit:Maybe(int),
    // side_effect_index:Maybe(int),
	cancel_states: [dynamic]int,
	hurtbox_list:  [dynamic]int, // width height extent will be static we may want to make it an index
	hitbox_list:   [dynamic]int, // index into the hit box array of the state
}

//This would improve cache locality by colocating hit and hurbox.
// and it would allow for a more packed file
MoveBox :: union {
    Hit_box,
    Hurt_box,
}
	// todo properties
//for multi hits spawn a new hitbox
Hit_box :: struct {
    box:psy.FixedBox,
	hitKnockback:     psy.Vec2Fixed, // this is applied to other
	hitPushback:      psy.Vec2Fixed, // this is applied to self
	blockKnockback:   psy.Vec2Fixed,
	blockPushback:    psy.Vec2Fixed,
	attackDir:        AttackDir,
    on_hit_index: Maybe(int),
    on_block_index:Maybe(int), // should these be distinct
	// todo properties
}

Hurt_box :: struct {
    using box:psy.FixedBox,
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
	delete(move.moveboxs)
	delete(move.frames)
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
