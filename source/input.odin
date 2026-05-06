package game

import gk "game_kernel"
import rl "vendor:raylib"
import "./utils"
@(require) import "core:log"
import "./netcode"



Controls :: union {
    Keyboard,
    GamePad,
    Remote, // used for testing
}

Remote :: struct {

}

Keyboard :: struct {
 up_key:rl.KeyboardKey,
 down_key:rl.KeyboardKey,
 left_key:rl.KeyboardKey,
 right_key:rl.KeyboardKey,
 light_key:rl.KeyboardKey,
 medium_key:rl.KeyboardKey,
 heavy_key:rl.KeyboardKey,
 dash_key:rl.KeyboardKey,
 debit_key:rl.KeyboardKey,
}

GamePad :: struct {
    gamepad:i32, // gamepad number from 0-4
    up_key:rl.GamepadButton,
    down_key:rl.GamepadButton,
    left_key:rl.GamepadButton,
    right_key:rl.GamepadButton,
    light_key:rl.GamepadButton,
    medium_key:rl.GamepadButton,
    heavy_key:rl.GamepadButton,
    dash_key:rl.GamepadButton,
    debit_key:rl.GamepadButton,
}

InputWithFrame :: struct {
    frame:int,
    input:gk.Input,
}
// this handles handing inputs from the game to the kernal
// it does not contain a buffer but it allows for delay
InputMannager :: struct {
   	controls: 	Controls,
    delay:       int,
	input_buffer: utils.FrameTrackedBuffer(gk.INPUT_BUFFER_LENGTH,gk.InputWithFrame),
	remote_inputs:utils.RingBuffer(MAX_NETWORK_WINDOW,gk.InputWithFrame),
	last_input: gk.InputWithFrame,
	network_mannager_ptr:^SessionMannager,
	remote:bool,
	inRemapMode:Maybe(^rl.KeyboardKey), //
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

        buttons:=[5]gk.Button {}
        index := 0
        if rl.IsKeyPressed(controls.light_key) {
            buttons[index] = gk.Button.Light
            index += 1
        }
        if rl.IsKeyPressed(controls.medium_key) {
            buttons[index] = gk.Button.Medium
            index += 1
        }
        if rl.IsKeyPressed(controls.heavy_key) {
            buttons[index] = gk.Button.Heavy
            index += 1
        }
        return gk.Input{
            dir=dir,
            attack=buttons,
        }
    case GamePad:
        // assert(false,"not implemented")
        move_vec := Vec2{}
        side_mod := 1
        if rl.IsGamepadAvailable(controls.gamepad) {
         	// assert(false,"getting game pad name")
        }
        if p1_side == false {
            side_mod =-1
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.up_key) {
            move_vec.y += 1
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.down_key) {
            move_vec.y += -1
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.right_key) {
            move_vec.x += f32(1 * side_mod)
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.left_key) {
            move_vec.x += f32(-1 * side_mod)
        }
        dir:gk.Direction
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
        buttons:=[5]gk.Button {}
        index := 0
        if rl.IsGamepadButtonDown(controls.gamepad,controls.light_key) {
            buttons[index] = gk.Button.Light
            index += 1
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.medium_key) {
            buttons[index] = gk.Button.Medium
            index += 1
        }
        if rl.IsGamepadButtonDown(controls.gamepad,controls.heavy_key) {
            buttons[index] = gk.Button.Heavy
            index += 1
        }
        return gk.Input{
            dir=dir,
            attack=buttons,
        }
    case Remote:
        return {}
    }
    return {}
}



push_to_input_buffer :: proc(mannager:^InputMannager,frame:int,p1_side:bool) -> int {
    if mannager.remote == true {
        return remote_rollback_and_prediction(mannager,frame)
    } else {
        input := poll_charecter_input(mannager.controls,p1_side)

        if mannager.remote == false && mannager.network_mannager_ptr.should_run == true {
            size,err := netcode.send_message(
                &mannager.network_mannager_ptr.udp,
                NetworkMessage {
                    packet_version= 0,
                    frame=frame+mannager.delay,
                    message_type=SendInput{
                        input=input,
                    },
                },frame+mannager.delay)

            if err != nil {
                log.debug(size)
                log.debug(err)
            }
        }
        utils.insert_at_frame(&mannager.input_buffer,gk.InputWithFrame{
            frame+mannager.delay, // add delay frames
            input,
        },frame+mannager.delay)
    }
    return -1
}

remote_rollback_and_prediction :: proc(mannager:^InputMannager,frame:int) -> int {
    log.debug("-------------- start of rollback")
    //predicting code
    // this needs to be a prtr that way the changes are percisted
    input_queue := &mannager.remote_inputs
    log.debug("read index",input_queue.read_index,"write index",input_queue.inner.index)
    length := utils.ring_len(input_queue)
    //if we have nothing in the queue say we dont need to rollback
    if length <= 0 {
        log.debug("predicting")
        utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
        return -1
    }
    //if the reader is too close to the writer we predict
    if input_queue.read_index+1 == input_queue.inner.index || input_queue.read_index == input_queue.inner.index{
        //prediction
        // this is bad we need to work on it
        utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
        log.debug("read index",input_queue.read_index,"write index",input_queue.inner.index)
        return -1
    }
    peeked_input := utils.ring_peek(input_queue)
    log.debug(peeked_input)
    // we keep peeking
    earlyest_frame := peeked_input.frame
    // drain if if we are behind
    for frame > peeked_input.frame  && input_queue.read_index+1 != input_queue.inner.index{
        // rollback!!!!!!
        // go back and insert the frame at the right pos.
        // then resimulate
        // check if predictions are correct
        if input_queue.read_index+1 == input_queue.inner.index || input_queue.read_index == input_queue.inner.index{
            break
        }
        prediction := utils.get_at_frame(mannager.input_buffer,peeked_input.frame)
       	input := utils.ring_pop(input_queue)
        log.debug("popped",input)
        if prediction.input == peeked_input.input {
        	// correct prediction keep draining the queue

            utils.insert_at_frame(&mannager.input_buffer,input,peeked_input.frame)
            // our prediction was right no need to rollback
        } else {
            // we have to rollback
            if input.frame < earlyest_frame {
                log.debug("updating earlyest frame to",earlyest_frame)
                //how far we have to go back
                earlyest_frame=input.frame
            }
            // insert the corrected input
            utils.insert_at_frame(&mannager.input_buffer,input,input.frame)
            //insert a prediction as well
        }
        peeked_input = utils.ring_peek(input_queue)
        // return input.frame
    }
    if earlyest_frame != frame {
        log.debug(peeked_input)
        log.debug("rollback to ",earlyest_frame)
        log.debug("read index",input_queue.read_index,"write index",input_queue.inner.index)
        return earlyest_frame
    }
    if frame < peeked_input.frame {
        // we are missing or packets are out of order we must predict for this frame
        log.debug("predicting because of missing")
        utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
        return -1
    }
    msg := utils.ring_pop(input_queue)
    utils.insert_at_frame(&mannager.input_buffer,msg,frame)
    return -1
}

insert_input_at_frame ::proc (mannager:^InputMannager,frame:int, input:gk.Input) {
    utils.insert_at_frame(&mannager.input_buffer,mannager.last_input,frame)
}

//this sucks
get_input_at_frame :: proc (mannager:^InputMannager,frame:int) -> gk.Input {
    // why are we out of sync
    // check if we have an input this frame.
    input := utils.get_at_frame(mannager.input_buffer,frame)
    if input.frame == frame {
        // if so return and pop
        mannager.last_input = input
        return input.input
    }
    // if not reuturn what we were doing last frame
    // awsome prediction
    // log.debug("no input at frame rollback may happen")
    // assert(false,"test")
    return mannager.last_input.input
}
