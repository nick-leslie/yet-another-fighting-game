package game_kernel


projectile :: struct {
	hitbox: Hit_box,
	hurtbox: Hurt_box, // we may need to put this on a projectile spesific layer or somethign
	move_dir: Vec3,
}
