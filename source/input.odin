package game

import "core:container/queue"
import "base:runtime"
import gk "game_kernel"
import rl "vendor:raylib"
@(require) import "core:log"



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

InputWithFrame :: struct {
    frame:int,
    input:gk.Input,
}

InputStack :: struct {
    stack:[dynamic]InputWithFrame,
    last_input:gk.Input,
}
// this handles handing inputs from the game to the kernal
// it does not contain a buffer but it allows for delay
InputMannager :: struct {
   	controls: 	Controls,
    delay:       int,
	input_stack: InputStack,
	network_mannager_ptr:^NetworkMannager,
	remote:bool,
}

make_input_stack:: proc(allocator:runtime.Allocator) -> InputStack {
    return InputStack {
        stack = make([dynamic]InputWithFrame,allocator),
        last_input = gk.Input {
            dir=gk.Direction.Neutral,
        },
    }
}

poll_charecter_input ::proc (controls:Controls,p1_side:bool) ->  gk.Input {
    switch &controls in controls {
    case Keyboard:
        move_vec := Vec2{}
        side_mod := 1
        if p1_side == false {
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
        dir:gk.Direction
        attack:gk.Attack
        switch move_vec {
        case {0,0}:
            dir = gk.Direction.Neutral
        case {1,0}:
            dir = gk.Direction.Forward
        case {-1,0}:
            dir = gk.Direction.Back
        case {0,-1}:
            dir = gk.Direction.Down
        case {0,1}:
            dir = gk.Direction.Up
        case {1,1}:
            dir = gk.Direction.UpForward
        case {-1,1}:
            dir = gk.Direction.UpBack
        case {1,-1}:
            dir = gk.Direction.DownForward
        case {-1,-1}:
            dir = gk.Direction.DownBack
        }
        if rl.IsKeyPressed(controls.light_key) {
            attack = gk.Attack.Light
        }
        if rl.IsKeyPressed(controls.medium_key) {
            attack = gk.Attack.Medium
        }
        if rl.IsKeyPressed(controls.heavy_key) {
            attack = gk.Attack.Heavy

        }
        return gk.Input{
            dir=dir,
            attack=attack,
        }
    case GamePad:
        assert(false,"not implemented")
        return {}
    }
    return {}
}


push_to_input_stack :: proc(mannager:^InputMannager,frame:int,p1_side:bool) {
    if mannager.remote == true {
        input_queue := &mannager.network_mannager_ptr.message_queue
        length := queue.len(input_queue^)
        if length <= 0 {
            log.debug("predicting")
            // assert(false,"predciting")
            //predict
            append_elem(&mannager.input_stack.stack, InputWithFrame{
                frame=frame,
                input=mannager.input_stack.last_input,
            })
            return
        }

        front_ptr := queue.front_ptr(input_queue)
        log.debug(front_ptr)
        if frame > front_ptr.frame {
            // rollback!!!!!!
            // go back and insert the frame at the right pos.
            // then resimulate
            assert(false,"rollback")
            //predict
            append_elem(&mannager.input_stack.stack, InputWithFrame{
                frame=frame,
                input=mannager.input_stack.last_input,
            })
            return
        }
        if frame < front_ptr.frame {
            // missing inputs we are predciting ask for input back
            log.debug("predicting because of missing")
            //predict
            append_elem(&mannager.input_stack.stack, InputWithFrame{
                frame=frame,
                input=mannager.input_stack.last_input,
            })
            return
        }
        log.debug("getting input")
        msg := queue.pop_front(input_queue)
        log.debug(msg)
        append_elem(&mannager.input_stack.stack,msg)
    } else {
        input := poll_charecter_input(mannager.controls,p1_side)

        msg := NetworkMessage {
            packet_version=0,
            frame=frame+mannager.delay,
            message_type=SendInput {
                input,
            },
        }
        if mannager.remote == false && g.network_mannager.should_run == true {
            size,err := send_messsage(mannager.network_mannager_ptr,msg)
            if err != nil {
                log.debug(size)
                log.debug(err)
            }
        }
        append_elem(&mannager.input_stack.stack, InputWithFrame{
            frame+mannager.delay, // add delay frames
            input,
        })
    }
    // todo we may want to move this into net
}


get_next_input :: proc (mannager:^InputMannager,frame:int) -> gk.Input {
    // check if we have an input this frame.
    if mannager.input_stack.stack[0].frame == frame {
        // if so return and pop
        input := mannager.input_stack.stack[0]
        // this may be slow
        ordered_remove(&mannager.input_stack.stack,0)
        mannager.input_stack.last_input = input.input
        return input.input
    }
    if frame > mannager.input_stack.stack[0].frame && mannager.remote {

    }
    // if not reuturn what we were doing last frame
    // awsome prediction
    return mannager.input_stack.last_input
}
