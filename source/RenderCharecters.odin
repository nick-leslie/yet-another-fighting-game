package game

// import "core:log"
import gk "game_kernel"
import rl  "vendor:raylib"
import psy "./physics"


charecter_draw :: proc(character: gk.CharecterBase($C,$C2)) {
	_,frame := gk.charecter_get_current_state_frame(character)
	char_body := psy.unfix_body(character.body)
	pos := [3]f32 {f32(char_body.position.x),f32(char_body.y),0}
	rl.DrawCapsule(
		pos,
		pos + UP * f32(gk.CHARACTER_CAPSULE_HALF_HEIGHT) * 2,
		f32(gk.CHARACTER_CAPSULE_RADIUS),
		16,
		8,
		rl.ORANGE,
	)
	for &hurt_box in frame.hurtbox_list {
        unfixed_box := psy.unfix_box(hurt_box)
		rl.DrawCube(
			pos + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
			f32(unfixed_box.extent.x),
			f32(unfixed_box.extent.y),
			0.0,
			rl.BLUE,
		)
	}
	for &enity in character.entity_pool {
		if enity.active == true {
			enity_state := enity.states[enity.current_state]
			enity_frame := enity_state.frames[enity.current_frame]
			entity_body := psy.unfix_body(enity.body)
			entity_pos_vec_3 := [3]f32{f32(entity_body.position.x),f32(entity_body.position.y),10}
			for &hurt_box in enity_frame.hurtbox_list {
			    unfixed_box := psy.unfix_box(hurt_box)
				rl.DrawCube(
					entity_pos_vec_3 + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
					f32(unfixed_box.extent.x),
					f32(unfixed_box.extent.y),
					0.0,
					rl.BLUE,
				)
			}
			for &hitbox_index in enity_frame.hitbox_list {
				hitbox := enity_state.hit_boxes[hitbox_index]
                unfixed_box := psy.unfix_box(hitbox.box)

				rl.DrawCube(
					entity_pos_vec_3 + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
					f32(unfixed_box.extent.x),
					f32(unfixed_box.extent.y),
					0.0,
					rl.RED,
				)
			}
		}
	}
}

charecter_draw_hit_boxes :: proc(character:gk.CharecterBase($C,$C2)) {
	state,frame := gk.charecter_get_current_state_frame(character)
	char_body := psy.unfix_body(character.body)
	pos := [3]f32 {f32(char_body.position.x),f32(char_body.y),0}
	for &hitbox_index in frame.hitbox_list {
		hitbox := state.hit_boxes[hitbox_index]
        unfixed_box := psy.unfix_box(hitbox.box)

		rl.DrawCube(
			pos + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
			f32(unfixed_box.extent.x),
			f32(unfixed_box.extent.y),
			0.0,
			rl.RED,
		)
	}
}
