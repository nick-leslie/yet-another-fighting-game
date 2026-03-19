package game_kernel


CharecterHooks :: struct {
	//required 
	damage_formula:proc(self:CharecterBase,other:CharecterBase,world:World,isCounter:bool,state:State(CharecterBase),hitbox:Hit_box) -> u32,
	charecter_check_counterhit: proc(striker:CharecterBase,struck:CharecterBase) -> bool,
	// on tic
	on_update:[dynamic]proc(self:^CharecterBase,world:^World),
	on_physics_update:[dynamic]proc(self:^CharecterBase,world:^World),
	on_self_hit_other:[dynamic]proc(self:^CharecterBase,other:^CharecterBase,world:^World,isCounter:bool,hitbox:Hit_box),
	// onBlocks
	onSelfBlocked:[dynamic]proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// onHit
	onSelfGotHit:[dynamic]proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// spawn projectile?
	selfSpawnProjectile:[dynamic]proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// onState change this one we may need to rework
	onSelfStateChange:[dynamic]proc(self:^CharecterBase,world:^World),
}

RenderHooks :: struct {
	// on tic
	onTic:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// onBlocks
	onSelfBlock:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// onHit
	onSelfHit:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// spawn projectile?
	spawnProjectile:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
	// onState change
	onStateChange:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
}
