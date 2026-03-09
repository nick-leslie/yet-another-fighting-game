package game

import clay "../libs/clay-odin"
import gk "game_kernel"
import "core:fmt"
import "core:unicode/utf8"
import psy "./physics"
@(require)import "core:log"

error_handler :: proc "c" (errorData: clay.ErrorData) {
    // Do something with the error data.
}

create_ui_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()({
        layout = {
            sizing = { width = clay.SizingGrow(), height = clay.SizingGrow() },
            padding = { 10,10,10,10 },
            layoutDirection = .TopToBottom,
        },
	}) {
		if clay.UI()({
			layout = {
	            sizing = {
					width = clay.SizingPercent(1),
					height = clay.SizingFit({}),
				 },
	            padding = { 10,10,10,10 },
				layoutDirection=.LeftToRight,
        	},
		}) {
			network_mannagment_ui()
			charecter_debug_ui(g.world.p1)
			charecter_debug_ui(g.world.p2)
		}
		input_history(g.world.p1_input_buffer)
		//todo fix these to the left and right
	}

    return clay.EndLayout()
}

input_history :: proc(buffer:gk.InputBuffer) {
	if clay.UI()({
		layout = {
			sizing = {
				width = clay.SizingGrow(),
				height = clay.SizingFit(),
			},
   			padding = { 10,10,10,10 },
    		layoutDirection = .LeftToRight,
		},
	}) {
		i := buffer.input_index-1
		// todo infinite loop fix me its bc of not using mod
		for i != buffer.input_index {
	  		i = i %% len(buffer.buffer)
			input_ui(buffer.buffer[i])
	        i-=1
            if i %% len(buffer.buffer) == buffer.input_index {
                break
            }
		}
	}
}

network_mannagment_ui :: proc() {
	if clay.UI(clay.ID("network_mannagment_layout"))({
		layout = {
			sizing = {
				width = clay.SizingGrow(),
				height = clay.SizingFit(),
			},
			padding = { 10,10,10,10 },
	  		layoutDirection = .LeftToRight,
		},

	}) {
		callback := proc "c" (d: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
			if pointerData.state == clay.PointerDataInteractionState.PressedThisFrame {
				context = g_context
				network_mannager_start_listening(&g.network_mannager)
			}
		}
		clay.OnHover(callback,nil)
		clay.Text("connect",clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}))
	}
}

input_ui:: proc(input:gk.Input) {
	char_arr := [3]rune{} // todo check if this works
	switch input.dir {
	case .Neutral:
		char_arr[0] = '.'
		char_arr[1] = ' '
	case .Forward:
		char_arr[0] = '-'
		char_arr[1] = '>'
	case .Back:
		char_arr[0] = '<'
		char_arr[1] = '-'
	case .Down:
		char_arr[0] = 'V'
	case .DownBack:
		char_arr[0] = 'V'
		char_arr[1] = '/'
	case .DownForward:
		char_arr[0] = '\\'
		char_arr[1] = 'V'
	case .Up:
		char_arr[0] = '^'
	case .UpBack:
		char_arr[0] = '^'
		char_arr[1] = '\\'
	case .UpForward:
		char_arr[0] = '/'
		char_arr[1] = '^'
	}
	switch input.attack {
	case .None:
		char_arr[2] = ' '
	case .Light:
		char_arr[2] = 'L'
	case .Medium:
		char_arr[2] = 'M'
	case .Heavy:
		char_arr[2] = 'H'
	}
	str := utf8.runes_to_string(char_arr[:],context.temp_allocator)
	clay.TextDynamic(
		str,
		clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
	)
}

charecter_debug_ui :: proc(charecter:gk.CharecterBase) {
	//todo add id
	if clay.UI()({
		layout = {
			sizing = {
				//todo make it so this doesnt resize when we add -
				width = clay.SizingGrow(),
				height = clay.SizingFit({}),
			},
			layoutDirection=.TopToBottom,
			childGap = 5,
		},

	}) {
	    body := psy.unfix_body(charecter.body)
		clay.TextDynamic(
			fmt.tprintfln("Health:%d",charecter.health),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
		)
		clay.TextDynamic(
			fmt.tprintfln("Pos:%v, Vel:%v",body.position,body.velocity),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255},wrapMode=.None}),
		)
		state,_ := gk.charecter_get_current_state_frame(charecter)
		clay.TextDynamic(
			fmt.tprintfln("State: %s",state.name),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
		)
		clay.TextDynamic(
			fmt.tprintfln("hit_stun:%d",charecter.hit_stun_frames),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
		)
		clay.TextDynamic(
			fmt.tprintfln("block_stun:%d",charecter.block_stun_frames),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
		)
	}
}


setup_clay :: proc(resolution:Vec2) -> clay.Arena {
	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size,)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(arena, {resolution.x,resolution.y}, { handler = error_handler })
	clay.SetMeasureTextFunction(measure_text, nil)
	return arena
}


measure_text :: proc "c" (
    text: clay.StringSlice,
    config: ^clay.TextElementConfig,
    userData: rawptr,
) -> clay.Dimensions {
    // clay.TextElementConfig contains members such as fontId, fontSize, letterSpacing, etc..
    // Note: clay.String->chars is not guaranteed to be null terminated
    return {
        width = f32(text.length * i32(config.fontSize)),
        height = f32(config.fontSize),
    }
}
