package game
import clay "../libs/clay-odin"



ControllerUiElement :: struct {
    on_click: Maybe(proc()),
    //do we put an action here
    up:int,
    down:int,
    left:int,
    right:int,
}
MENU_INTERACTIVE_ELEMENTS :: 10 // todo expand
create_menu_ui_layout :: proc(controller_map:^[MENU_INTERACTIVE_ELEMENTS]ControllerUiElement) -> clay.ClayArray(clay.RenderCommand) {
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
				childAlignment= {
				    x = .Center,
				    y = .Center,
				},
           	},
		}) {
		    //todo figure out a better way
		    callback := proc () {
				g.screen = InRound {}
			}
			clay_callback := proc "c" (d: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
       	        context = g_context
                if pointerData.state == clay.PointerDataInteractionState.PressedThisFrame {
                    g.screen = InRound {}
                }
            }
			controller_map[0] = ControllerUiElement {
			    on_click=callback,
				left = 0,
				right = 0,
				up = 0,
				down = 0,
			}
            static_button("start",false,clay.TextConfig({fontSize=50,letterSpacing=2,fontId=0,textColor={255,255,255,255}}),clay_callback)
		}
	}
    return clay.EndLayout()
}


// on_click :: proc(callback:proc()) -> proc "c" (d: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
//     return proc "c" (d: clay.ElementId, pointerData: clay.PointerData, userData: rawptr) {
// 		context = g_context
//         if pointerData.state == clay.PointerDataInteractionState.PressedThisFrame {
//             callback()
//         }
// 	}
// }
