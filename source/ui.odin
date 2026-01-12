package game

import clay "../libs/clay-odin"
import gk "game_kernel"
import "core:fmt"

error_handler :: proc "c" (errorData: clay.ErrorData) {
    // Do something with the error data.
}

create_ui_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI()({
        layout = {
            sizing = { width = clay.SizingGrow(), height = clay.SizingGrow() },
            padding = { 10,10,10,10 },
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
			charecter_debug_ui(g.world.p1)
			charecter_debug_ui(g.world.p2)
		}
		//todo fix these to the left and right
	}

    return clay.EndLayout()
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

		clay.TextDynamic(
			fmt.tprintfln("Health:%d",charecter.health),
			clay.TextConfig({fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),
		)
		clay.TextDynamic(
			fmt.tprintfln("Pos:%v",charecter.velocity),
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
