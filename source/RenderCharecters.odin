package game

import gk "game_kernel"
import rl  "vendor:raylib"

charecter_draw :: proc(character: gk.CharecterBase) {
	_,frame := gk.charecter_get_current_state_frame(character)
	rl.DrawCapsule(
		character.position,
		character.position + UP * gk.CHARACTER_CAPSULE_HALF_HEIGHT * 2,
		gk.CHARACTER_CAPSULE_RADIUS,
		16,
		8,
		rl.ORANGE,
	)
	for &hurt_box in frame.hurtbox_list {
		rl.DrawCube(
			character.position + hurt_box.position,
			hurt_box.extent.x,
			hurt_box.extent.y,
			0.0,
			rl.BLUE,
		)
	}
}

charecter_draw_hit_boxes :: proc(character:gk.CharecterBase) {
	state,frame := gk.charecter_get_current_state_frame(character)
	for &hitbox_index in frame.hitbox_list {
		hitbox := state.hit_boxes[hitbox_index]
		rl.DrawCube(
			character.position + hitbox.position,
			hitbox.extent.x,
			hitbox.extent.y,
			0.0,
			rl.RED,
		)
	}
}
