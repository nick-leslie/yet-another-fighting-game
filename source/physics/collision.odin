package physics

import fixed "core:math/fixed"
@(require) import "core:log"

// collisions

check_body_body_collsion :: proc(a_box:FixedBox,a_body:FixedBody,b_box:FixedBox,b_body:FixedBody) -> bool {
    a_box := a_box
    b_box := b_box
    a_box.position = add_fixed_vecs(a_box.position,a_body.position)
    b_box.position = add_fixed_vecs(b_box.position,b_body.position)
    return check_box_box_collision(a_box,b_box)
}
check_body_static_collsion :: proc(a_box:FixedBox,a_body:FixedBody,b_box:FixedBox) -> bool {
    a_box := a_box
    a_box.position = add_fixed_vecs(a_box.position,a_body.position)
    return check_box_box_collision(a_box,b_box)
}

check_box_box_collision :: proc(a: FixedBox, b: FixedBox) -> bool {
    two_fixed := Fixed12_4{}
    fixed.init_from_f64(&two_fixed, 2.0)

    a_half_width := fixed.div(a.extent.x, two_fixed)
    a_half_height := fixed.div(a.extent.y, two_fixed)
    b_half_width := fixed.div(b.extent.x, two_fixed)
    b_half_height := fixed.div(b.extent.y, two_fixed)

    return (
        fixed.add(a.x, a_half_width).i >= fixed.sub(b.x, b_half_width).i &&
        fixed.sub(a.x, a_half_width).i <= fixed.add(b.x, b_half_width).i &&
        fixed.add(a.y, a_half_height).i >= fixed.sub(b.y, b_half_height).i &&
        fixed.sub(a.y, a_half_height).i <= fixed.add(b.y, b_half_height).i
    )
}
check_box_line_collision :: proc(box:Box(Fixed12_4), plane:[4]Fixed12_4) -> bool {
	two_fixed := Fixed12_4 {}
	fixed.init_from_f64(&two_fixed,2.0)
	box_half_width := fixed.div(box.extent.x,two_fixed)
	box_half_height := fixed.div(box.extent.y,two_fixed)
	//-w -h  t1 * ----- * t2 +w -h
	//        |       |
	//        |    p  |
	//-w +h b1 * ----- * b2 +w +h
	t1 := [2]Fixed12_4{fixed.sub(box.x,box_half_width),fixed.sub(box.y,box_half_height)}
	t2 := [2]Fixed12_4{fixed.add(box.x,box_half_width),fixed.sub(box.y,box_half_height)}
	b1 := [2]Fixed12_4{fixed.sub(box.x,box_half_width),fixed.add(box.y,box_half_height)}
	b2 := [2]Fixed12_4{fixed.add(box.x,box_half_width),fixed.add(box.y,box_half_height)}

	l := line_line(plane,{t1.x,t1.y,b1.x,b1.y}) // left
	r := line_line(plane,{t2.x,t2.y,b2.x,b2.y}) // right
	t := line_line(plane,{t1.x,t1.y,t2.x,t2.y}) // top
	b := line_line(plane,{b1.x,b1.y,b2.x,b2.y}) // bot
	return l || r || t|| b // return if we overlap anywere
}

line_line :: proc(a: [4]Fixed12_4, b: [4]Fixed12_4) -> bool {
    // a represents line 1: (a.x, a.y) to (a.z, a.w)
    // b represents line 2: (b.x, b.y) to (b.z, b.w)

    // Calculate denominator
    denominator := fixed.sub(
        fixed.mul(fixed.sub(b.w, b.y), fixed.sub(a.z, a.x)),
        fixed.mul(fixed.sub(b.z, b.x), fixed.sub(a.w, a.y)),
    )

    // Calculate uA
    uA := fixed.div(
        fixed.sub(
            fixed.mul(fixed.sub(b.z, b.x), fixed.sub(a.y, b.y)),
            fixed.mul(fixed.sub(b.w, b.y), fixed.sub(a.x, b.x)),
        ),
        denominator,
    )

    // Calculate uB
    uB := fixed.div(
        fixed.sub(
            fixed.mul(fixed.sub(a.z, a.x), fixed.sub(a.y, b.y)),
            fixed.mul(fixed.sub(a.w, a.y), fixed.sub(a.x, b.x)),
        ),denominator)

    // Check if uA and uB are between 0-1
    zero_fixed := Fixed12_4 {}
	fixed.init_from_f64(&zero_fixed,0)
    one_fixed := Fixed12_4 {}
	fixed.init_from_f64(&one_fixed,1)

    return uA.i >= zero_fixed.i &&
    uA.i <= one_fixed.i &&
    uB.i >= zero_fixed.i &&
    uB.i <= one_fixed.i
}


check_horizontal_plane_col :: proc(box:Box(Fixed12_4), y:Fixed12_4,check_top:bool) -> bool {
   	two_fixed := Fixed12_4 {}
	fixed.init_from_f64(&two_fixed,2.0)
	half_height := fixed.div(box.extent.y,two_fixed)
	if check_top == false {
	    return fixed.sub(box.position.y,half_height).i <= y.i
	}
    return fixed.add(box.position.y,half_height).i >= y.i
}
