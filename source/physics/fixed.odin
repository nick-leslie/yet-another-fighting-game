package physics

import fixed "core:math/fixed"
@(require) import "core:log"


Fixed12_4 :: distinct fixed.Fixed(i16,6) // fixed
Vec2Fixed ::  [2]Fixed12_4
Vec3Fixed ::  [3]Fixed12_4

// Fixed16_16
// todo add a where to force it to be an int
RiggedBody :: struct($T:typeid) {
	using position:    [2]T,
	velocity:          [2]T,
	prev_position:     [2]T, //do we need this
	prev_velocity:     [2]T, //do we need this
}

FixedBody :: RiggedBody(Fixed12_4)
FixedBox :: Box(Fixed12_4)
UnfixedBox :: Box(f64)

Box :: struct($T:typeid) {
	using position:   [2]T,
	extent:           [2]T,
}
// general

body_init :: proc(pos:[4]i16) -> FixedBody {
    return FixedBody {
        position = vec2_init(pos),
        velocity = {},
    }
}

// a float with front back parts
box_init :: proc(pos:[4]i16,extent:[4]i16) -> FixedBox {
    box := FixedBox {
        position = vec2_init(pos),
        extent = vec2_init(extent),
    }
    // assert(false)
    return box
}

vec2_init :: proc(vec:[4]i16) -> Vec2Fixed {
    return Vec2Fixed{
        init_from_parts(vec.x,vec.y),
        init_from_parts(vec.z,vec.w),
    }
}

// unfix body should only be used for rendering and should not be used for game play
// fix_body :: proc(body:RiggedBody(f64)) -> RiggedBody(Fixed12_4) {
//     vec_fixed := [8]Fixed12_4 {}
//    	fixed.init_from_f64(&vec_fixed[0],body.position.x)
//     fixed.init_from_f64(&vec_fixed[1],body.position.y)
//    	fixed.init_from_f64(&vec_fixed[2],body.prev_position.x)
//     fixed.init_from_f64(&vec_fixed[3],body.prev_position.y)
//     fixed.init_from_f64(&vec_fixed[4],body.velocity.x)
//     fixed.init_from_f64(&vec_fixed[5],body.velocity.y)
//     fixed.init_from_f64(&vec_fixed[6],body.prev_velocity.x)
//     fixed.init_from_f64(&vec_fixed[7],body.prev_velocity.y)
//     //todo convert the body out of float
// 	return RiggedBody(Fixed12_4) {
// 		position = {vec_fixed[0],vec_fixed[1]},
// 		prev_position = {vec_fixed[2],vec_fixed[3]},
// 		velocity = {vec_fixed[4],vec_fixed[5]},
// 		prev_velocity = {vec_fixed[6],vec_fixed[7]},
// 	}
// }

// unfix body should only be used for rendering and should not be used for game play
unfix_body :: proc(body:RiggedBody(Fixed12_4)) -> RiggedBody(f64) {
	//todo convert the body out of float
	return RiggedBody(f64) {
		position = {fixed.to_f64(body.position.x),fixed.to_f64(body.position.y)},
		velocity = {fixed.to_f64(body.velocity.x),fixed.to_f64(body.velocity.y)},
		prev_position = {fixed.to_f64(body.prev_position.x),fixed.to_f64(body.prev_position.y)},
		prev_velocity = {fixed.to_f64(body.prev_velocity.x),fixed.to_f64(body.prev_velocity.y)},
	}
}

unfix_box :: proc(box:Box(Fixed12_4)) -> Box(f64) {
	//todo convert the body out of float
	return Box(f64) {
		position = {fixed.to_f64(box.position.x),fixed.to_f64(box.position.y)},
		extent = {fixed.to_f64(box.extent.x),fixed.to_f64(box.extent.y)},
	}
}
// physics
move_by_vel :: proc(body:^RiggedBody(Fixed12_4)) -> ^RiggedBody(Fixed12_4) {
    delta := init_from_parts(0,17)

	body.position = Vec2Fixed {
		fixed.add(body.position.x,fixed.mul(body.velocity.x,delta)),
		fixed.add(body.position.y,fixed.mul(body.velocity.y,delta)),
	}
	return body
}

set_box_by_body :: proc(box:FixedBox,body:FixedBody) -> FixedBox {
    box := box
    box.position = add_fixed_vecs(box.position,body.position)
    return box
}

invert_fixed :: proc(val:Fixed12_4) -> Fixed12_4 {
    return fixed.mul(val, init_from_parts(-1,0))
}
invert_vec :: proc(val:Vec2Fixed) -> Vec2Fixed {
    return Vec2Fixed{
        invert_fixed(val.x),
        invert_fixed(val.y),
    }
}

add_float_vec3_to_vel:: proc (body:^RiggedBody(Fixed12_4),vec:[3]f64) -> ^RiggedBody(Fixed12_4) {
    vec_fixed := float_vec3_to_fixed(vec)
	body.velocity = Vec2Fixed {
		fixed.add(body.velocity.x,vec_fixed.x),
		fixed.add(body.velocity.y,vec_fixed.y),
	}
	return body
}
add_float_vec2_to_vel:: proc (body:^RiggedBody(Fixed12_4),vec:[2]f64) -> ^RiggedBody(Fixed12_4) {
    vec_fixed := float_vec2_to_fixed(vec)
	body.velocity = Vec2Fixed {
		fixed.add(body.velocity.x,vec_fixed.x),
		fixed.add(body.velocity.y,vec_fixed.y),
	}
	return body
}
add_fixed_vec2_to_vel:: proc (body:^RiggedBody(Fixed12_4),vec:[2]Fixed12_4) -> ^RiggedBody(Fixed12_4) {
	body.velocity = Vec2Fixed {
		fixed.add(body.velocity.x,vec.x),
		fixed.add(body.velocity.y,vec.y),
	}
	return body
}
add_fixed_vec3_to_vel:: proc (body:^RiggedBody(Fixed12_4),vec:[3]Fixed12_4) -> ^RiggedBody(Fixed12_4) {
	body.velocity = Vec2Fixed {
		fixed.add(body.velocity.x,vec.x),
		fixed.add(body.velocity.y,vec.y),
	}
	return body
}

// depreacted todo figure out how to do this
// or figure out how to take any static 2 + len vec
float_vec3_to_fixed :: proc(vec:[3]f64) -> [2]Fixed12_4 {
   	vec_fixed := [2]Fixed12_4 {}
	fixed.init_from_f64(&vec_fixed.x,vec.x)
	fixed.init_from_f64(&vec_fixed.y,vec.y)
    return vec_fixed
}
float_vec2_to_fixed :: proc(vec:[2]f64) -> [2]Fixed12_4 {
   	vec_fixed := [2]Fixed12_4 {}
	fixed.init_from_f64(&vec_fixed.x,vec.x)
	fixed.init_from_f64(&vec_fixed.y,vec.y)
    return vec_fixed
}

init_from_parts :: proc(front:i16,back:i16) -> Fixed12_4{
	value := Fixed12_4 {}
	fixed.init_from_parts(&value,front,back)
	// log.debug(value)
	// log.debug(fixed_to_f64(value))
	return value
}

f64_to_fixed :: proc(val:f64) -> Fixed12_4 {
    // log.warn("this should only be called at start of game")
   	val_fixed := Fixed12_4 {}
	fixed.init_from_f64(&val_fixed,val)
	return val_fixed
}
fixed_to_f64 :: proc(val:Fixed12_4) -> f64 {
    return fixed.to_f64(val)
}

// fix_box :: proc(box:Box(f64)) -> FixedBox {
//    	vec_fixed := [4]Fixed12_4 {}
// 	fixed.init_from_f64(&vec_fixed.x,box.position.x)
// 	fixed.init_from_f64(&vec_fixed.y,box.position.y)
// 	fixed.init_from_f64(&vec_fixed.z,box.extent.x)
// 	fixed.init_from_f64(&vec_fixed.w,box.extent.y)
// 	return FixedBox {
//         position = {vec_fixed.x,vec_fixed.y},
//         extent = {vec_fixed.z,vec_fixed.w},
// 	}
// }

add_fixed_vecs :: proc(vec1:[2]Fixed12_4,vec2:[2]Fixed12_4) -> [2]Fixed12_4 {
    return [2]Fixed12_4{
        fixed.add(vec1.x,vec2.x),
        fixed.add(vec1.y,vec2.y),
    }
}

