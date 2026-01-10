package game

import clay "../libs/clay-odin"

error_handler :: proc "c" (errorData: clay.ErrorData) {
    // Do something with the error data.
}

initalise_memory :: proc(resolution:Vec2) -> clay.Arena {
	min_memory_size := clay.MinMemorySize()
	memory := make([^]u8, min_memory_size,)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(uint(min_memory_size), memory)
	clay.Initialize(arena, {resolution.x,resolution.y}, { handler = error_handler })
	clay.SetMeasureTextFunction(measure_text, nil)
	return arena
}

create_ui_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()


    return clay.EndLayout()
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
