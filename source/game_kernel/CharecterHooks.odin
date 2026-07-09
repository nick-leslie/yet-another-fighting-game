package game_kernel
import vmem "core:mem/virtual"


CharecterHooks :: struct($CU:typeid) {
	//required
	// we set this as mutable so we can affect combo scalling
	damage_formula:proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State,hitbox:Hit_box) -> u32,
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
	//--------------- move and frame hooks
	// when a move hits self
	onFrame: [dynamic]proc(self: ^CharecterBase(CU),world:^World(CU)),
	moveCheckExit:[dynamic]proc(self: ^CharecterBase(CU), state: state_index) -> bool,
	moveOnHit:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)), // todo fill me out all the on hit function pointer
	moveOnBlock:[dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)), // todo fill me out all the on block function pointer
}


initilize_charecter_hooks :: proc(char: ^CharecterBase($CU)) {
   	arena_alocator := vmem.arena_allocator(&char.arena)
    char.hooks.onFrame = make([dynamic]proc(self: ^CharecterBase(CU),world:^World(CU)),arena_alocator)
    char.hooks.moveCheckExit = make([dynamic]proc(self: ^CharecterBase(CU), frame: state_index) -> bool,arena_alocator)
    char.hooks.moveOnHit = make([dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)),arena_alocator)
    char.hooks.moveOnBlock = make([dynamic]proc(self:^CharecterBase(CU),other:^CharecterBase(CU),world:^World(CU)),arena_alocator)
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


push_function :: proc(array: ^$T/[dynamic]$E,type:E) -> function_index {
    append(array,type)
    return function_index(len(array)-1)
}

make_default_dammage_formula :: proc($CU:typeid) -> proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State,hitbox:Hit_box) -> u32{
    return proc(self:CharecterBase(CU),other:CharecterBase(CU),world:World(CU),isCounter:bool,state:State,hitbox:Hit_box) -> u32 {
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
