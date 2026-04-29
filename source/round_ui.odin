package game

import "core:fmt"
import clay "../libs/clay-odin"
import gk "game_kernel"
@(require)import "core:log"


round_top_ui :: proc() {
    if clay.UI()({
           layout = {
               sizing = { width = clay.SizingGrow(), height = clay.SizingFit() },
               padding = { 10,10,10,10 },
               layoutDirection = .LeftToRight,
               childGap=10,
           },
		}) {
        health_bar_ui(g.world.p1)
        timer_ui(10)
        health_bar_ui(g.world.p2)
	}
}


timer_ui :: proc(time:u32) {
  		clay.TextDynamic(
		fmt.tprintfln("%d",time),
		clay.TextConfig({
		fontSize=20,letterSpacing=2,fontId=0,textColor={255,255,255,255},textAlignment=.Center}),
	)
}

health_bar_ui :: proc(char:gk.CharecterBase($CU)) {
    if clay.UI(clay.ID("Health-outer"))({
        layout = {
            sizing = {
                width = clay.SizingGrow(),
                height = clay.SizingFixed(20),
            },
            layoutDirection = .LeftToRight,
        },
        border = {
            color = {0,0,255,255},
            width = {5,5,5,5,0},
        },
    }) {
        if clay.UI(clay.ID("Health-inner"))({
            layout = {
                sizing = {
                    width = clay.SizingPercent((f32(char.serlized_state.health)/f32(char.max_health))),
                    height = clay.SizingGrow(),
                },
                layoutDirection = .LeftToRight,
            },
            backgroundColor = {255,255,255,255},
        }) {
        }
    }
}
