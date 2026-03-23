package game_kernel


CharecterHooks :: struct($C:typeid) {
	//required
	damage_formula:proc(self:CharecterBase(C),other:CharecterBase(C),world:World(C,any),isCounter:bool,state:State(CharecterBase(C)),hitbox:Hit_box) -> u32,
	charecter_check_counterhit: proc(self:CharecterBase(C),other:CharecterBase(C)) -> bool,
	// on tic
	on_update:[dynamic]proc(self:^CharecterBase(C),world:^World(C,any)),
	on_physics_update:[dynamic]proc(self:^CharecterBase(C),world:^World(any,any)),
	on_self_hit_other:[dynamic]proc(self:^CharecterBase(C),other:^CharecterBase(C),world:^World(C,any),isCounter:bool,hitbox:Hit_box),
	// onBlocks
	onSelfBlocked:[dynamic]proc(self:^CharecterBase(C),other:^CharecterBase(any),world:^World(any,any)),
	// onHit
	onSelfGotHit:[dynamic]proc(self:^CharecterBase(C),other:^CharecterBase(any),world:^World(any,any)),
	// spawn projectile?
	selfSpawnProjectile:[dynamic]proc(self:^CharecterBase(C),other:^CharecterBase(any),world:^World(any,any)),
	// onState change this one we may need to rework
	onSelfStateChange:[dynamic]proc(self:^CharecterBase(C),world:^World(any,any)),
}

// RenderHooks :: struct {
// 	// on tic
// 	onTic:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
// 	// onBlocks
// 	onSelfBlock:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
// 	// onHit
// 	onSelfHit:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
// 	// spawn projectile?
// 	spawnProjectile:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
// 	// onState change
// 	onStateChange:proc(self:^CharecterBase,other:^CharecterBase,world:^World),
// }


default_dammage_formula :: proc(self:CharecterBase($C),other:CharecterBase(any),world:World(C,any),isCounter:bool,state:State(CharecterBase(C)),hitbox:Hit_box) -> u32 {
    if self.combo_scaling > 0 do return state.damage / self.combo_scaling
    return 0
}

default_counterhit_check :: proc(self:CharecterBase($C),other:CharecterBase(any)) -> bool {
    _, struck_frame := charecter_get_current_state_frame(other)
    return struck_frame.frame_type == .Startup || struck_frame.frame_type == .Active
}
