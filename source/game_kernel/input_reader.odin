#+feature dynamic-literals
package game_kernel

@(require)import "core:log"
@(require)import "core:reflect"
@(require)import "core:testing"
import "../utils"
// import "core:log"

Direction :: enum {
    Neutral,
    Forward,
    Back,
    Up,
    UpBack,
    UpForward,
    Down,
    DownBack,
    DownForward,
}


Button :: enum {
    None,
    Light,
    Medium,
    Heavy,
    Dash,
    Unique,
}

ButtonPressType :: enum {
    Tapped,   // pressed on this frame todo do we want it to be tapped for 1-2 frames
    Held,     // held accross frames
    Released, // released on this frame
}

ButtonPress :: struct {
    button:Button,
    PressType:ButtonPressType,
}

Input :: struct {
    dir:Direction,
    //todo add a negitive edge support
    attack:[5]Maybe(ButtonPress),
}

InputWithFrame :: struct {
    frame:int,
    input:Input,
}


Pattern :: struct {
    //we will always alocate these with a cap pre alocated
    // these are essently fixed. could we use code gen?
    inputs:       [dynamic]Input,
    pritority:    int,
    state_index:  state_index,
    // we may want to also add a only in air check
    air_ok:       bool,
    air_only:     bool,
}

delete_pattern :: proc(pattern:^Pattern) {
    delete(pattern.inputs)
}

// seperate this out to another layer
// gets the controls for the player that frame

InputBuffer :: struct {
    buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),
    //this is for charge input support todo figure me out tmrw
    current_dir:Direction,
    frames_held_dir:int,
    button_frames_held:[Button]int,
}

update_input_buffer :: proc(input_buffer:^utils.Buffer(INPUT_BUFFER_LENGTH,Input),input:Input) {
	utils.push(input_buffer,input)
}
INPUT_BUFFER_LENGTH :: 25
//look at how tks work and refne. right now we cant handle input of the same type before the attack type
// could we speed this up with a binary tree
pick_state :: proc(buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),pattern_list:[dynamic]Pattern,in_air:bool) -> state_index {
    // could we stack alocate this
    // we use the tmp alocator so that we can delete it at the end of each frame
    pattern_input_index := make([dynamic]int,len(pattern_list),context.temp_allocator)
    i:= buffer.index
    for i != buffer.index+1 {
        // log.debug(i)
        //
        i = i %% len(buffer.buffer)
        // if(i < 0) {
        //     i=INPUT_BUFFER_LENGTH-1
        // }
        // log.debug(i)
        input := buffer.buffer[i]
        // log.info(input)
        for j:=0;j< len(pattern_list);j+=1 {
            pattern := pattern_list[j]
            check_index := pattern_input_index[j]
            if check_index == len(pattern.inputs) || check_index == -1{
                // we know this pattern is qalifed break the loop
                continue
            }
            // we may want to
            if (pattern.air_ok == false && in_air == true) || pattern.air_only == true && in_air == false{
                //disqalify based on air state
                pattern_input_index[j] = -1
                continue
            }
            check_input := pattern.inputs[check_index]
            if check_input == input {
                pattern_input_index[j] +=1
            } else {
            	if check_index > 0 && pattern.inputs[check_index-1] == input {
           			continue // dont mark for extra inputs
             	}
                // disqualify the pattern
                pattern_input_index[j] = -1
            }
        }
        i-=1
        if i %% len(buffer.buffer) == buffer.index {
            break
        }
    }
    // find the highest priority move
    highest_priority:= 0
    highest_index :=   0
    for i=0;i<len(pattern_list);i+=1 {
        check_index := pattern_input_index[i]
        pattern := pattern_list[i]
        if check_index != len(pattern.inputs) {
            // log.debug(pattern)
            // we know this pattern is qalifed break the loop
            continue
        }
        if pattern.pritority >= highest_priority {
            highest_priority = pattern.pritority
            highest_index =  i
        }
    }
    // if highest_index == 1 {/
    //     //my guess is this happens when we reset?
    //     log.debug(pattern_list[highest_index].state_index)
    //     assert(false,"random forward state")
    // }
    return pattern_list[highest_index].state_index
}



@(test)
test_quarter_circle :: proc(t: ^testing.T) {
	patterns := make([dynamic]Pattern)
	pattern_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 6,
	}
	pattern2_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 6,
	}
	pattern3_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Back, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 6,
	}

	append(&patterns,pattern_light_attack)
	append(&patterns,pattern2_light_attack)
	append(&patterns,pattern3_light_attack)

	pattern_quarter_circle := Pattern {
		inputs      = {
			Input{dir = Direction.Forward, attack = {ButtonPress {
				button=Button.Light,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
			Input{dir = Direction.DownForward, attack = {ButtonPress {
				button=Button.None,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
			Input{dir = Direction.Down, attack = {ButtonPress {
				button=Button.None,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_2_quarter_circle := Pattern {
		inputs  = {
			Input{dir = Direction.Forward, attack = {ButtonPress {
				button=Button.Light,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
			Input{dir = Direction.Neutral, attack = {ButtonPress {
				button=Button.None,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
			Input{dir = Direction.DownForward, attack = {ButtonPress {
				button=Button.None,
				PressType=.Tapped,
			},nil,nil,nil,nil }},
			Input{dir = Direction.Down, attack = {ButtonPress {
				button=Button.None,
				PressType=.Tapped,
			},nil,nil,nil,nil}},
		},
		pritority   = 2,
		state_index = 7,
	}
	append(&patterns,pattern_quarter_circle)
	append(&patterns,pattern_2_quarter_circle)

	input_buffer := utils.Buffer(INPUT_BUFFER_LENGTH,Input) {}
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = {ButtonPress {button=Button.None,PressType=.Tapped,},nil,nil,nil,nil}})
	update_input_buffer(&input_buffer,Input{dir = Direction.Forward, attack = {ButtonPress {button=Button.Light,PressType=.Tapped,},nil,nil,nil,nil}})

	out_state := pick_state(input_buffer,patterns,false)
	log.info(out_state)
	testing.expect(t,out_state==7,"our out state failed to be 7. light attack beat the higher priority quarter circle")
	free_all(context.allocator) // this is so we dont memory leak with dynamic allocs
}


@(test)
test_throw :: proc(t: ^testing.T) {
   	patterns := make([dynamic]Pattern)
    pattern_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Forward, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 0,
	}
	pattern2_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 0,
	}
	pattern3_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Back, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},nil,nil,nil,nil}}},
		pritority   = 1,
		state_index = 0,
	}
	append(&patterns,pattern_light_attack)
	append(&patterns,pattern2_light_attack)
	append(&patterns,pattern3_light_attack)
	throw_pattern := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = {ButtonPress {
			button=Button.Light,
			PressType=.Tapped,
		},ButtonPress {
			button=Button.Medium,
			PressType=.Tapped,
		},nil,nil,nil}}},
		pritority   = 2,
		state_index = 1,
	}
	append(&patterns,throw_pattern)

   	input_buffer := utils.Buffer(INPUT_BUFFER_LENGTH,Input) {}
    update_input_buffer(&input_buffer,Input{dir = Direction.Neutral, attack = {ButtonPress {button=Button.Light,PressType=.Tapped,},ButtonPress {button=Button.Medium,PressType=.Tapped,},nil,nil,nil}})

	out_state := pick_state(input_buffer,patterns,false)
	log.info(out_state)
	testing.expect(t,out_state==1,"our out state failed to be ehter mutli buttons dont work. or prioritys dont work")
	free_all(context.allocator) // this is so we dont memory leak with dynamic allocs
}
