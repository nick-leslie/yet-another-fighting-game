package game

import "core:log"
import "core:strings"
import clay "../libs/clay-odin"
import rl "vendor:raylib"

clay_color_to_raylib_color :: proc(color:clay.Color) -> rl.Color {
	assert(false,"not done")
	return {}
}

clay_raylib_render :: proc (renderCommands:^clay.ClayArray(clay.RenderCommand),fonts:[dynamic]rl.Font) {
	for i:i32 = 0; i < renderCommands.length; i+=1 {
		render_command := clay.RenderCommandArray_Get(renderCommands,i)^
		bounding_box := render_command.boundingBox // todo may round this
		switch render_command.commandType {
		case .Text:
			text_data := render_command.renderData.text
			font_to_use := fonts[text_data.fontId]
			str := strings.clone_from_ptr(
				text_data.stringContents.chars,
				int(text_data.stringContents.length),
				context.temp_allocator, // deleted at end of frame. may change if we start using 2 frame arenas
			)
			string_to_use := strings.clone_to_cstring(str,context.temp_allocator)
			rl.DrawTextEx(font_to_use,
				string_to_use,
				{bounding_box.x,bounding_box.y},
				f32(text_data.fontSize),
				f32(text_data.letterSpacing),
				clay_color_to_raylib_color(text_data.textColor),
			)
		case .Image:
			//see if there is a better way without auto_cast
			image_texture:^rl.Texture2D = auto_cast(render_command.renderData.image.imageData)
			tint_color := render_command.renderData.image.backgroundColor
   			if tint_color.r == 0 && tint_color.g == 0 && tint_color.b == 0 && tint_color.a == 0 {
                tint_color =  { 255, 255, 255, 255 }
            }
            rl.DrawTexturePro(
           		image_texture^,
             	{0,0,f32(image_texture.width), f32(image_texture.height)},
              	{bounding_box.x,bounding_box.y,bounding_box.width,bounding_box.height},
               	{},
                0,
                clay_color_to_raylib_color(tint_color),
            )
		case .ScissorStart:
			rl.BeginScissorMode(
				// may need to round
				i32(bounding_box.x),
				i32(bounding_box.y),
				i32(bounding_box.width),
				i32(bounding_box.height),
			)
		case .ScissorEnd:
			rl.EndScissorMode()
		case .Rectangle:
			config := render_command.renderData.rectangle
			if config.cornerRadius.topLeft > 0 {
				radius := config.cornerRadius.topLeft * 2 / bounding_box.height if bounding_box.width > bounding_box.height else bounding_box.width
				rl.DrawRectangleRounded(
    				{bounding_box.x,bounding_box.y,bounding_box.width,bounding_box.height},
     				radius,
         			8,
          			clay_color_to_raylib_color(config.backgroundColor),
				)
			} else {
				rl.DrawRectangle(
					i32(bounding_box.x),
					i32(bounding_box.y),
					i32(bounding_box.width),
					i32(bounding_box.height),
					clay_color_to_raylib_color(config.backgroundColor),
				)
			}
		case .Border:
			config := render_command.renderData.border
			if config.width.left > 0 {
				rl.DrawRectangle(
					i32(bounding_box.x),
					i32(bounding_box.y + config.cornerRadius.topLeft),
					i32(config.width.left),
					i32(bounding_box.height - config.cornerRadius.topLeft - config.cornerRadius.bottomLeft),
					clay_color_to_raylib_color(config.color),
				)
			}
			if config.width.right > 0 {
				rl.DrawRectangle(
					i32(bounding_box.x + bounding_box.width - f32(config.width.right)),
					i32(bounding_box.y + config.cornerRadius.topRight),
					i32(config.width.right),
					i32(bounding_box.height - config.cornerRadius.topRight - config.cornerRadius.bottomRight),
					clay_color_to_raylib_color(config.color),
				)

			}
			if config.width.top > 0 {
				rl.DrawRectangle(
					i32(bounding_box.x + config.cornerRadius.topLeft),
					i32(bounding_box.y),
					i32(bounding_box.width - config.cornerRadius.topLeft -config.cornerRadius.topRight),
					i32(config.width.top),
					clay_color_to_raylib_color(config.color),
				)
			}
			if config.width.bottom > 0 {
				rl.DrawRectangle(
					i32(bounding_box.x + config.cornerRadius.bottomLeft),
					i32(bounding_box.y + bounding_box.height - f32(config.width.bottom)),
					i32(bounding_box.width - config.cornerRadius.bottomLeft - config.cornerRadius.bottomRight),
					i32(config.width.bottom),
					clay_color_to_raylib_color(config.color),
				)

			}
			if config.cornerRadius.topLeft > 0 {
				rl.DrawRing(
					{bounding_box.x + config.cornerRadius.topLeft, bounding_box.y + config.cornerRadius.topLeft },
					config.cornerRadius.topLeft - f32(config.width.top),
				 	config.cornerRadius.topLeft,
					180,
					270,
					10,
					clay_color_to_raylib_color(config.color),
				)
			}
			if config.cornerRadius.topRight > 0 {
				rl.DrawRing(
					{ bounding_box.x + bounding_box.width - config.cornerRadius.topRight,bounding_box.y + config.cornerRadius.topRight },
					config.cornerRadius.topRight - f32(config.width.top),
					config.cornerRadius.topRight,
					270,
					360,
					10,
					clay_color_to_raylib_color(config.color),
				)

			}
			if config.cornerRadius.bottomLeft > 0 {
				rl.DrawRing(
					{ bounding_box.x + config.cornerRadius.bottomLeft, bounding_box.y + bounding_box.height - config.cornerRadius.bottomLeft },
					config.cornerRadius.bottomLeft - f32(config.width.bottom),
					config.cornerRadius.bottomLeft,
					90,
					180,
					10,
					clay_color_to_raylib_color(config.color),
				)

			}
			if config.cornerRadius.bottomRight > 0 {
				rl.DrawRing({ bounding_box.x + bounding_box.width - config.cornerRadius.bottomRight, bounding_box.y + bounding_box.height - config.cornerRadius.bottomRight },
					config.cornerRadius.bottomRight - f32(config.width.bottom),
					config.cornerRadius.bottomRight,
					0.1,
					90,
					10,
					clay_color_to_raylib_color(config.color),
				)

			}
		case .Custom:
			log.debug("not implemented")
		case .None:
		}
	}
}
