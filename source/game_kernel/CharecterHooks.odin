package game_kernel


CharecterHooks :: struct($CU:typeid) {
	//required
	damage_formula:proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State(CharecterBase(CU),CU),hitbox:Hit_box) -> u32,
	charecter_check_counterhit: proc(self:CharecterBase(CU),other:CharecterBase(CU)) -> bool,
	// on tic
	on_update:[dynamic]proc(self:^CharecterBase(CU),world:^World(CU)),
	on_physics_update:[dynamic]proc(self:^CharecterBase(CU),world:^World(CU)),
	on_self_hit_other:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU),isCounter:bool,hitbox:Hit_box),
	// onBlocks
	onSelfBlocked:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)),
	// onHit
	onSelfGotHit:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)),
	// spawn projectile?
	selfSpawnProjectile:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)),
	// onState change this one we may need to rework
	onSelfStateChange:[dynamic]proc(self:^CharecterBase(CU),world:^World(CU)),
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

make_default_dammage_formula :: proc($CU:typeid) -> proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State(CharecterBase(CU),CU),hitbox:Hit_box) -> u32{
    return proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State(CharecterBase(CU),CU),hitbox:Hit_box) -> u32 {
        //TODO FIX ME
        if self.combo_scaling > 0 do return u32(self.combo_scaling / state.damage)
        return 0
    }
}


make_default_counterhit_check :: proc($CU:typeid) -> proc(self:CharecterBase(CU),other:CharecterBase(CU)) -> bool {
    return proc(self:CharecterBase(CU),other:CharecterBase(CU)) -> bool {
        _, struck_frame := charecter_get_current_state_frame(other)
        return struck_frame.frame_type == .Startup || struck_frame.frame_type == .Active
    }
}
