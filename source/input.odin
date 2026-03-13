package game

import "core:container/queue"
import "base:runtime"
import gk "game_kernel"
import rl "vendor:raylib"
import "./utils"
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
	input_buffer: utils.FrameTrackedBuffer(gk.INPUT_BUFFER_LENGTH,InputWithFrame),
	last_input: InputWithFrame,
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


push_to_input_stack :: proc(mannager:^InputMannager,frame:int,p1_side:bool) -> int {
    if mannager.remote == true {
        input_queue := &mannager.network_mannager_ptr.message_queue
        length := queue.len(input_queue^)
        if length <= 0 {
            log.debug("predicting")
            // assert(false,"predciting")
            //predict

            utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
            return 0
        }

        front_ptr := queue.front_ptr(input_queue)
        log.debug(front_ptr)
        if frame > front_ptr.frame {
            // rollback!!!!!!
            // go back and insert the frame at the right pos.
            // then resimulate
            // check if predictions are correct
            prediction := utils.get_at_frame(mannager.input_buffer,front_ptr.frame)
            if prediction.input == front_ptr.input {
                queue.pop_front(input_queue)
                // our prediction was right no need to rollback
                return 0
            }
            log.debug(frame)
            log.debug(front_ptr)
            // assert(false,"rollback")
            queue.pop_front(input_queue)
            //predict

            utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
            return front_ptr.frame
        }
        if frame < front_ptr.frame {
            // missing inputs we are predciting ask for input back
            log.debug("predicting because of missing")
            //predict
            // todo this may be wrong
            utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
            return 0
        }
        log.debug("getting input")
        msg := queue.pop_front(input_queue)
        log.debug(msg)
        utils.insert_at_frame(&mannager.input_buffer,msg,frame)
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
        utils.insert_at_frame(&mannager.input_buffer,InputWithFrame{
            frame+mannager.delay, // add delay frames
            input,
        },frame+mannager.delay)
    }
    return 0
    // todo we may want to move this into net
}


get_next_input :: proc (mannager:^InputMannager,frame:int) -> gk.Input {
    // check if we have an input this frame.
    input := utils.get_at_frame(mannager.input_buffer,frame)
    if input.frame == frame {
        // if so return and pop
        return input.input
    }
    // if not reuturn what we were doing last frame
    // awsome prediction
    return mannager.input_stack.last_input
}
