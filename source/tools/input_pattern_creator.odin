    #+feature dynamic-literals
package tools
import gk "../game_kernel"
@(require)import "core:log"
import "core:testing"
import "base:runtime"

number_notation_to_pattern :: proc(
    notation:string,
    state_index:int,
    priority:int,
    air_ok:bool,
    air_only:bool,
    allocator:runtime.Allocator,
) -> gk.Pattern {
    inputs := make_dynamic_array([dynamic]gk.Input,allocator)
    for i := len(notation)-1; i >= 0; i-=1 {
        // r is of type `rune`
        char := notation[i]
	    dir:gk.Direction
		attack:gk.Button
		//todo allow for diffent button tupes
        switch char {
        case 'l':
            attack = gk.Button.Light
        case 'm':
            attack = gk.Button.Medium
        case 'h':
            attack = gk.Button.Heavy
        case 'd':
            attack = gk.Button.Dash
        case 'u':
            attack = gk.Button.Unique
        case:
            attack=gk.Button.None
        }
        if attack != gk.Button.None {
            assert(i-1 >= 0,"we cant put an input at the end")
            i-=1
            char = notation[i]
        }
        switch char {
        case '1':
            dir = gk.Direction.DownBack
        case '2':
            dir = gk.Direction.Down
        case '3':
            dir = gk.Direction.DownForward
        case '4':
            dir = gk.Direction.Back
        case '5':
            dir = gk.Direction.Neutral
        case '6':
            dir = gk.Direction.Forward
        case '7':
            dir = gk.Direction.UpBack
        case '8':
            dir = gk.Direction.Up
        case '9':
            dir = gk.Direction.UpForward
        }
        append(&inputs, gk.Input {
            dir=dir,
            attack={gk.ButtonPress {
                button=attack,
                PressType=gk.ButtonPressType.Tapped,
            },nil,nil,nil,nil},
        })
    }
    pattenrn := gk.Pattern{
        inputs=inputs,
        pritority=priority,
        state_index=state_index,
        air_ok=air_ok,
        air_only=air_only,
    }
    log.info("made pattern",pattenrn)
    return pattenrn
}

@(test)
test_quarter_circle_notation :: proc(t: ^testing.T) {
    pattern := number_notation_to_pattern("236l",0,2,true,false,context.temp_allocator)
    control := gk.Pattern {
		inputs  = {
			gk.Input{dir = gk.Direction.Forward, attack = {gk.ButtonPress {
                button=gk.Button.Light,
                PressType=gk.ButtonPressType.Tapped,
            },nil,nil,nil,nil}},
			gk.Input{dir = gk.Direction.DownForward, attack = {nil,nil,nil,nil,nil}},
			gk.Input{dir = gk.Direction.Down, attack = {nil,nil,nil,nil,nil}},
		},
		pritority   = 2,
		state_index = 0,
		air_ok = true,
	}
    testing.expect_value(t,pattern.pritority, control.pritority)
    testing.expect_value(t,pattern.state_index, control.state_index)
    testing.expect_value(t,pattern.air_ok, control.air_ok)
    testing.expect_value(t,pattern.air_only, control.air_only)
    testing.expect_value(t,len(pattern.inputs), len(control.inputs))
    for i:=0; i<len(pattern.inputs); i+=1 {
        testing.expect_value(t,pattern.inputs[i].dir, control.inputs[i].dir)
    }
    free_all(context.temp_allocator)
    free_all(context.allocator)
}
@(test)
test_6_l_notation :: proc(t: ^testing.T) {
    pattern := number_notation_to_pattern("6l",0,0,true,false,context.temp_allocator)
    control := gk.Pattern {
		inputs  = {
			gk.Input{dir = gk.Direction.Forward, attack = {gk.ButtonPress {
                button=gk.Button.Light,
                PressType=gk.ButtonPressType.Tapped,
            },nil,nil,nil,nil}},
		},
		pritority   = 0,
		state_index = 0,
		air_ok = true,
	}
    testing.expect_value(t,pattern.pritority, control.pritority)
    testing.expect_value(t,pattern.state_index, control.state_index)
    testing.expect_value(t,pattern.air_ok, control.air_ok)
    testing.expect_value(t,pattern.air_only, control.air_only)
    testing.expect_value(t,len(pattern.inputs), len(control.inputs))
    for i:=0; i<len(pattern.inputs); i+=1 {
        testing.expect_value(t,pattern.inputs[i].dir, control.inputs[i].dir)
    }
    free_all(context.temp_allocator)
    free_all(context.allocator)
}
