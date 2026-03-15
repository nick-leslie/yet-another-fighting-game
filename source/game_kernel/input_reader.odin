#+feature dynamic-literals
package game_kernel

import "core:testing"
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

Attack :: enum {
    None,
    Light,
    Medium,
    Heavy,
}

Input :: struct {
    dir:Direction,
    attack:Attack,
}


Pattern :: struct {
    //we will always alocate these with a cap pre alocated
    // these are essently fixed. could we use code gen?
    inputs:       [dynamic]Input,
    pritority:    int,
    state_index:   int,
}

delete_pattern :: proc(pattern:^Pattern) {
    delete(pattern.inputs)
}

// seperate this out to another layer
// gets the controls for the player that frame


update_input_buffer :: proc(input_buffer:^utils.Buffer(INPUT_BUFFER_LENGTH,Input),input:Input) {
	utils.push(input_buffer,input)
}
// this is still too buggy
//todo test this becca
INPUT_BUFFER_LENGTH :: 25
// could we speed this up with a binary tree
pick_state :: proc(buffer:utils.Buffer(INPUT_BUFFER_LENGTH,Input),pattern_list:[dynamic]Pattern) -> int {
    // could we stack alocate this
    // we use the tmp alocator so that we can delete it at the end of each frame
    pattern_input_index := make([dynamic]int,len(pattern_list),context.temp_allocator)
    i:= buffer.index-1
    for i != buffer.index {
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
            if pattern.inputs[check_index] == input {
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
		inputs      = {Input{dir = Direction.Forward, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern2_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Neutral, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}
	pattern3_light_attack := Pattern {
		inputs      = {Input{dir = Direction.Back, attack = Attack.Light}},
		pritority   = 1,
		state_index = 6,
	}

	append(&patterns,pattern_light_attack)
	append(&patterns,pattern2_light_attack)
	append(&patterns,pattern3_light_attack)

	pattern_quarter_circle := Pattern {
		inputs      = {
			Input{dir = Direction.Forward, attack = Attack.Light},
			Input{dir = Direction.DownForward, attack = Attack.None},
			Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	pattern_2_quarter_circle := Pattern {
		inputs  = {
			Input{dir = Direction.Forward, attack = Attack.Light},
			Input{dir = Direction.Neutral, attack = Attack.None},
			Input{dir = Direction.DownForward, attack = Attack.None},
			Input{dir = Direction.Down, attack = Attack.None},
		},
		pritority   = 2,
		state_index = 7,
	}
	append(&patterns,pattern_quarter_circle)
	append(&patterns,pattern_2_quarter_circle)

	input_buffer := utils.Buffer(INPUT_BUFFER_LENGTH,Input) {}
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.Down, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.DownForward, attack = Attack.None})
	update_input_buffer(&input_buffer,Input{dir = Direction.Forward, attack = Attack.Light})

	out_state := pick_state(input_buffer,patterns)
	testing.expect(t,out_state==7,"our out state failed to be 7. light attack beat the higher priority quarter circle")
	free_all(context.allocator) // this is so we dont memory leak with dynamic allocs
}
