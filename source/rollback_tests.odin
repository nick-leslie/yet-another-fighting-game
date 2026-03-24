package game
// import "core:log"
// import gk "game_kernel"
// import psy "./physics"

// @test
// rollback_test :: proc () {
//    	p1_controls := DebugControls {}
//    	p2_controls := DebugControls {}

//    	p1 := gk.CharecterBase {
// 		health=200,
// 		body = psy.body_init({0, 10}),
// 		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2}),
// 		move_speed = psy.f64_to_fixed(7),
// 		air_drag = psy.f64_to_fixed(0.5),
// 		air_move_speed = psy.f64_to_fixed(15.0),
// 		jump_height = psy.f64_to_fixed(50.0),
// 		p1_side = true,
// 	}
// 	p2 := gk.CharecterBase {
// 		health=100,
// 		body = psy.body_init({0, 10}),
// 		collision_box = psy.box_init({gk.CHARACTER_CAPSULE_RADIUS*2, gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2}),
// 		move_speed = psy.f64_to_fixed(7),
// 		air_drag = psy.f64_to_fixed(0.5),
// 		air_move_speed = psy.f64_to_fixed(15.0),
// 		jump_height = psy.f64_to_fixed(50.0),
// 		p1_side = true,
// 	}
// 	add_state_movement(&p1) // the nill is tmp
// 	add_state_movement(&p2) // the nill is tmp
// 	world := gk.world_init(p1,p2)
// 	gk.initilize_charecter_memory(&p1)
// 	gk.initilize_charecter_memory(&p2)
// 	p1_input_mannager:=InputMannager {
//             controls=p1_controls,
//             remote = false,
//             network_mannager_ptr = &g.network_mannager,
//             delay = 0,
// 	}
// 	p2_input_mannager:=InputMannager {
//             controls=p2_controls,
//             remote = true,
//             network_mannager_ptr = &g.network_mannager,
//             delay = 0,
// 	}
// 	log.debug(world)
// 	log.debug(p1_input_mannager)
// 	log.debug(p2_input_mannager)
// }
