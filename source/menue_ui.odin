package game
import clay "../libs/clay-odin"



ControllerUiElement :: struct {
    //do we put an action here
    up:^ControllerUiElement,
    down:^ControllerUiElement,
    left:^ControllerUiElement,
    right:^ControllerUiElement,
}
MENUE_INTERACTIVE_ELEMENTS :: 10 // todo expand 
create_menue_ui_layout :: proc([$N]ControllerUiElement) -> clay.ClayArray(clay.RenderCommand) {
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

		}
	}
    return clay.EndLayout()
}
