package game_kernel


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


MAX_PATTERN_LEN :: 7 // we set this to be the length of 6321456 (strive super input)
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

InputBuffer ::struct {
    buffer:     [INPUT_BUFFER_LENGTH]Input,
    input_index:int,
}
// seperate this out to another layer
// gets the controls for the player that frame


update_input_buffer :: proc(charecter:^CharecterBase,input:Input) {
    charecter.input_buffer.buffer[charecter.input_buffer.input_index] = input
    charecter.input_buffer.input_index +=1
    if charecter.input_buffer.input_index >= INPUT_BUFFER_LENGTH-1 {
        charecter.input_buffer.input_index=0
    }
}


INPUT_BUFFER_LENGTH :: 20
// could we speed this up with a binary tree
pick_state :: proc(buffer:InputBuffer,pattern_list:[dynamic]Pattern) -> int {
    // could we stack alocate this
    // we use the tmp alocator so that we can delete it at the end of each frame
    pattern_input_index := make([dynamic]int,len(pattern_list),context.temp_allocator)
    i:= buffer.input_index-1
    for i != buffer.input_index {
        //
        if(i <= 0) {
            i=INPUT_BUFFER_LENGTH-1
        } else if(i == INPUT_BUFFER_LENGTH-1) {
            i=0
        }
        input := buffer.buffer[i]
        for j:=0;j< len(pattern_list);j+=1 {
            pattern := pattern_list[j]
            check_index := pattern_input_index[j]
            if check_index == len(pattern.inputs) || check_index == -1{
                // we know this pattern is qalifed break the loop
                continue
            }
            if pattern.inputs[check_index] == input {
                // disqualify the pattern
                pattern_input_index[j] +=1
            } else {
                pattern_input_index[j] = -1
            }
        }
        i-=1
    }
    // log.debug(pattern_input_index)
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
            highest_index    =   i
        }
    }
    // if highest_index == 1 {
    //     //my guess is this happens when we reset?
    //     log.debug(pattern_list[highest_index].state_index)
    //     assert(false,"random forward state")
    // }
    return pattern_list[highest_index].state_index
}
