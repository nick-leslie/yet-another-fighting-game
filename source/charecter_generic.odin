#+feature dynamic-literals
package game
// import rl "vendor:raylib"
import "core:log"


move_forward :: proc(char:^Charecter) {
    zero_frame := Frame {
        frame_index=0,
        frame_type=FrameType.Active,
        hurtbox_list={
            Hurt_box{
                position=Vec2{0,0},
                extent=Vec2{50.,100.},
            },
        },
        hitbox_list={},
        on_frame=proc(char:^Charecter) {
            if char.p1_side do char.move_dir=Vec3{1,0,0}
            if !char.p1_side do char.move_dir=Vec3{-1,0,0}
        },
    }
    move := Move {
        // model_ptr=model_prt,
        // animation_ptr=animation_ptr,
        frames={zero_frame},
    }
    log.debug("in setting up physics")
    setup_move_physics(&move)
    append(&char.moves,move)
}

move_backward :: proc(char:^Charecter) {
    zero_frame := Frame {
        frame_index=0,
        frame_type=FrameType.Active,
        hurtbox_list={
            Hurt_box{
                position=Vec2{0,0},
                extent=Vec2{50.,100.},
            },
        },
        hitbox_list={},
        on_frame=proc(char:^Charecter) {
            if char.p1_side do char.move_dir=Vec3{-1,0,0}
            if !char.p1_side do char.move_dir=Vec3{1,0,0}
        },
    }
    move := Move {
        // model_ptr=model_prt,
        // animation_ptr=animation_ptr,
        frames={zero_frame},
    }

    setup_move_physics(&move)
    append(&char.moves,move)
}
move_jump :: proc(char:^Charecter) {
    zero_frame := Frame {
        frame_index=0,
        frame_type=FrameType.Active,
        hurtbox_list={
            Hurt_box{
                position=Vec2{0,0},
                extent=Vec2{50.,100.},
            },
        },
        hitbox_list={},
        on_frame=proc(char:^Charecter) {
            char.move_dir=Vec3{0,1,0}
        },
    }
    move := Move {
        // model_ptr=model_prt,
        // animation_ptr=animation_ptr,
        frames={zero_frame},
    }

    setup_move_physics(&move)
    append(&char.moves,move)
}
move_jump_forward :: proc(char:^Charecter) {
    zero_frame := Frame {
        frame_index=0,
        frame_type=FrameType.Active,
        hurtbox_list={
            Hurt_box{
                position=Vec2{0,0},
                extent=Vec2{50.,100.},
            },
        },
        hitbox_list={},
        on_frame=proc(char:^Charecter) {
            if char.p1_side do char.move_dir=Vec3{1,1,0}
            if !char.p1_side do char.move_dir=Vec3{-1,1,0}
        },
    }
    move := Move {
        // model_ptr=model_prt,
        // animation_ptr=animation_ptr,
        frames={zero_frame},
    }

    setup_move_physics(&move)
    append(&char.moves,move)
}
move_jump_backward :: proc(char:^Charecter) {
    zero_frame := Frame {
        frame_index=0,
        frame_type=FrameType.Active,
        hurtbox_list={
            Hurt_box{
                position=Vec2{0,0},
                extent=Vec2{50.,100.},
            },
        },
        hitbox_list={},
        on_frame=proc(char:^Charecter) {
            if char.p1_side do char.move_dir=Vec3{-1,1,0}
            if !char.p1_side do char.move_dir=Vec3{1,1,0}
        },
    }
    move := Move {
        // model_ptr=model_prt,
        // animation_ptr=animation_ptr,
        frames={zero_frame},
    }
    setup_move_physics(&move)
    append(&char.moves,move)
}

pattern_forward ::proc(char:^Charecter){
    pattern := Pattern {
        inputs = {
            Input{dir=Direction.Forward,attack=Attack.None},
        },
        pritority=0,
        move_index=0,
    }
    append(&char.patterns,pattern)
}
pattern_backward ::proc(char:^Charecter){
    pattern := Pattern {
        inputs = {
            Input{dir=Direction.Back,attack=Attack.None},
        },
        pritority=0,
        move_index=1,
    }
    append(&char.patterns,pattern)
}
pattern_jump ::proc(char:^Charecter){
    pattern := Pattern {
        inputs = {
            Input{dir=Direction.Up,attack=Attack.None},
        },
        pritority=0,
        move_index=2,
    }
    append(&char.patterns,pattern)
}
pattern_jump_forward ::proc(char:^Charecter){
    pattern := Pattern {
        inputs = {
            Input{dir=Direction.UpForward,attack=Attack.None},
        },
        pritority=0,
        move_index=3,
    }
    append(&char.patterns,pattern)
}
pattern_jump_backward ::proc(char:^Charecter){
    pattern := Pattern {
        inputs = {
            Input{dir=Direction.UpBack,attack=Attack.None},
        },
        pritority=0,
        move_index=4,
    }
    append(&char.patterns,pattern)
}

add_move_movement :: proc(char:^Charecter) {
    log.debug("in add movement")
    move_forward(char)
    move_backward(char)
    move_jump(char)
    move_jump_forward(char)
    move_jump_backward(char)
    log.debug("done adding movement")

    //add the move patterns
    pattern_forward(char)
    pattern_backward(char)
    pattern_jump(char)
    pattern_jump_forward(char)
    pattern_jump_backward(char)
    log.debug("done adding patterns")
}
