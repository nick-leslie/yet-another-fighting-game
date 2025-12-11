package game
import rl "vendor:raylib"
// import "core:log"


Direction :: enum {
    Forward,
    Back,
    Neutral,
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

Controls :: union {
    Keyboard,
    GamePad,
}

Keyboard :: struct {
 up_key:rl.KeyboardKey,
 down_key:rl.KeyboardKey,
 left_key:rl.KeyboardKey,
 right_key:rl.KeyboardKey,
 light_key:rl.KeyboardKey,
 medium_key:rl.KeyboardKey,
 heavy_key:rl.KeyboardKey,
}

GamePad :: struct {
    light_key:rl.GamepadButton,
    medium_key:rl.GamepadButton,
    heavy_key:rl.GamepadButton,
}

MAX_PATTERN_LEN :: 7 // we set this to be the length of 6321456 (strive super input)
Pattern :: struct {
    //we will always alocate these with a cap pre alocated
    // these are essently fixed. could we use code gen?
    inputs:       [dynamic]Input,
    pritority:    int,
    move_index:   int,
}

InputBuffer ::struct {
    buffer:     [INPUT_BUFFER_LENGTH]Input,
    input_index:int,
}

// gets the controls for the player that frame
poll_charecter_input ::proc (charecter:^Charecter) -> Input{
    switch &controls in charecter.controls {
    case Keyboard:
        move_vec := Vec2{}
        side_mod := 1
        if charecter.p1_side == false {
            side_mod =-1
        }
        if rl.IsKeyDown(controls.up_key) {
            move_vec.y += 1
        }
        if rl.IsKeyDown(controls.down_key) {
            move_vec.y += -1
        }
        if rl.IsKeyDown(controls.right_key) {
            move_vec.x += f32(1 * side_mod)
        }
        if rl.IsKeyDown(controls.left_key) {
            move_vec.x += f32(-1 * side_mod)
        }
        dir:Direction
        switch move_vec {
        case {0,0}:
            dir = Direction.Neutral
        case {1,0}:
            dir = Direction.Forward
        case {-1,0}:
            dir = Direction.Back
        case {0,-1}:
            dir = Direction.Down
        case {0,1}:
            dir = Direction.Up
        case {1,1}:
            dir = Direction.UpForward
        case {-1,1}:
            dir = Direction.UpBack
        case {1,-1}:
            dir = Direction.DownForward
        case {-1,-1}:
            dir = Direction.DownBack
        }
        return Input{
            dir=dir,
            attack=Attack.None,
        }
    case GamePad:
        assert(false,"not implemented")
        return {}
    }
    return {}
}

update_input_buffer :: proc(charecter:^Charecter) {
    input := poll_charecter_input(charecter)
    charecter.input_buffer.buffer[charecter.input_buffer.input_index] = input
    charecter.input_buffer.input_index +=1
    if charecter.input_buffer.input_index >= INPUT_BUFFER_LENGTH {
        charecter.input_buffer.input_index=0
    }
}


INPUT_BUFFER_LENGTH :: 20
// could we speed this up with a binary tree
pick_state :: proc(buffer:[INPUT_BUFFER_LENGTH]Input,pattern_list:[dynamic]Pattern) -> ^Pattern {
    // could we stack alocate this
    pattern_input_index := make([dynamic]int,len(pattern_list))
    defer delete(pattern_input_index)

    for i:=0; i < INPUT_BUFFER_LENGTH;i+=1{
        input := buffer[i]
        for j:=0;j< len(pattern_list);j+=1 {
            pattern := pattern_list[j]
            check_index := pattern_input_index[i]
            if check_index == len(pattern.inputs) || check_index == -1{
                // we know this pattern is qalifed break the loop
                continue
            }
            if pattern.inputs[check_index] == input {
                // disqualify the pattern
                pattern_input_index[i] +=1
            } else {
                pattern_input_index[i] = -1
            }
        }
    }
    // find the highest priority move
    highest_priority:= 0
    highest_index :=   0
    for i:=0;i<len(pattern_list);i+=1 {
        check_index := pattern_input_index[i]
        pattern := pattern_list[i]
        if check_index != len(pattern.inputs) {
            // we know this pattern is qalifed break the loop
            continue
        }
        if pattern.pritority > highest_priority {
            highest_priority = pattern.pritority
            highest_index    =   i
        }
    }
    return &pattern_list[highest_index]
}
