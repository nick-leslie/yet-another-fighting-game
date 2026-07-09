package rendering

// import "core:log"
import gk "../game_kernel"
import rl  "vendor:raylib"
import psy "../physics"

CAMERA_DISTANCE :: 70
CAMERA_POSITION :: Vec3{0, 0, CAMERA_DISTANCE}
CAMERA_TARGET   :: Vec3 {0,25,0}
Vec3 :: [3]f32
Vec364 :: [3]f64
Vec2 :: [2]f32
Vec264 :: [2]f64
Vec4 :: [4]f32

Quat :: quaternion128

FLOOR_POSITION: Vec3 = {0, 0, 0}
QUAT_IDENTITY: Quat = 1
VEC3_ZERO: Vec3 = 0
UP :: Vec3{0, 1, 0}
FLOOR_EXTENT: Vec3={150, 0.05, 10}

charecter_draw :: proc(character: gk.CharecterBase($C)) {
	state,frame := gk.charecter_get_current_state_frame(character)
	char_body := psy.unfix_body(character.body)
	pos := [3]f32 {f32(char_body.position.x),f32(char_body.y),0}
	if frame.frame_type == .Startup {
    	rl.DrawCapsule(
    		pos,
    		pos + UP * f32(gk.CHARACTER_CAPSULE_HALF_HEIGHT) * 2,
    		f32(gk.CHARACTER_CAPSULE_RADIUS),
    		16,
    		8,
    		rl.DARKBLUE,
    	)
        first_active_drew:=false
        for i := 0; i < len(state.frames); i += 1 {
            future_frame := state.frames[i]
            if future_frame.frame_type == .Active && first_active_drew==false {
                for j := 0; j < len(future_frame.hitbox_list); j += 1 {
                    hitbox := state.moveboxs[future_frame.hitbox_list[j]]
                    unfixed_box := psy.unfix_box(hitbox.(gk.Hit_box).box)
              		rl.DrawCube(
             			pos + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
             			f32(unfixed_box.extent.x),
             			f32(unfixed_box.extent.y),
             			0.0,
             			rl.RED,
              		)
                }
                first_active_drew = true
            }
        }

	} else {
    	rl.DrawCapsule(
    		pos,
    		pos + UP * f32(gk.CHARACTER_CAPSULE_HALF_HEIGHT) * 2,
    		f32(gk.CHARACTER_CAPSULE_RADIUS),
    		16,
    		8,
    		rl.ORANGE,
    	)
	}


	for hurt_box_index in frame.hurtbox_list {
        unfixed_box := psy.unfix_box(state.moveboxs[hurt_box_index].(gk.Hurt_box).box)
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
			for hurt_box_index in enity_frame.hurtbox_list {
			    unfixed_box := psy.unfix_box(enity_state.moveboxs[hurt_box_index].(gk.Hurt_box).box)
				rl.DrawCube(
					entity_pos_vec_3 + {f32(unfixed_box.position.x),f32(unfixed_box.position.y),0},
					f32(unfixed_box.extent.x),
					f32(unfixed_box.extent.y),
					0.0,
					rl.BLUE,
				)
			}
			for hitbox_index in enity_frame.hitbox_list {
				hitbox := enity_state.moveboxs[hitbox_index]
                unfixed_box := psy.unfix_box(hitbox.(gk.Hit_box).box)

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

charecter_draw_hit_boxes :: proc(character:gk.CharecterBase($C)) {
	state,frame := gk.charecter_get_current_state_frame(character)
	char_body := psy.unfix_body(character.body)
	pos := [3]f32 {f32(char_body.position.x),f32(char_body.y),0}
	for &hitbox_index in frame.hitbox_list {
		hitbox := state.moveboxs[hitbox_index].(gk.Hit_box)
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
