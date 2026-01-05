package game

import gk "game_kernel"
import rl "vendor:raylib"

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
