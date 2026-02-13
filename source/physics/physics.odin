package physics

import fixed "core:math/fixed"

Fixed12_4 :: distinct fixed.Fixed(i16,4) // fixed
Vec2Fixed ::  [2]Fixed12_4
Vec3Fixed ::  [3]Fixed12_4

// Fixed16_16
//todo make me a generic
// todo add a where to force it to be an int
RiggedBody :: struct($T:typeid) {
	using position:    [2]T,
	velocity:          [2]T,
	prev_position:     [2]T, //do we need this
	prev_velocity:     [2]T, //do we need this
}

Box :: struct {
	using position:   Vec2Fixed,
	extent:           Vec2Fixed,
}

unfix_body :: proc(body:^RiggedBody(Fixed12_4)) {
	//todo convert the body out of float
}

move_by_vel :: proc(body:^RiggedBody(Fixed12_4)) -> ^RiggedBody(Fixed12_4) {
	body.position = Vec2Fixed {
		fixed.add(body.position.x,body.velocity.x),
		fixed.add(body.position.y,body.velocity.y)
	}
	return body
}

check_box_collision :: proc(a:Box,b:Box) -> bool {
	two_fixed := Fixed12_4 {}
	fixed.init_from_f64(&two_fixed,2.0)
	a_half_width := fixed.div(a.extent.x,two_fixed)
	a_half_height := fixed.div(a.extent.y,two_fixed)
	b_half_width := fixed.div(b.extent.x,two_fixed)
	b_half_height := fixed.div(b.extent.y,two_fixed)
	return (
	 fixed.add(a.x, a_half_width).i >= b.x.i &&
	 a.x.i <= fixed.add(b.x, b_half_width).i &&
	fixed.add(a.y, a_half_height).i >= b.y.i &&
	a.y.i <= fixed.add(b.y,b_half_height).i
	)
}
