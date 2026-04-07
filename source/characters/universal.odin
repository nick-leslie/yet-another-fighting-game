package characters

import gk "../game_kernel"


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

exit_block_stun_proc :: proc(char: gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    if char.block_stun_frames <= 0 {
        return true
    }
    return false
}


on_hit_stun_proc :: proc(char: ^gk.CharecterBase(Charecter)) {
    char.hit_stun_frames -= 1
}

on_block_stun_proc :: proc(char: ^gk.CharecterBase(Charecter))  {
    char.block_stun_frames -= 1
}

exit_hit_stun_proc ::  proc(char: ^gk.CharecterBase(Charecter), cancel_index: int) -> bool {
    if char.hit_stun_frames <= 0 {
        return true
    }
    return false
}
