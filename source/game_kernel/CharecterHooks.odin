package game_kernel

HOOK_FUNCTION:: proc(self:^CharecterBase,other:^CharecterBase,world:^World)

CharecterHooks :: struct {
	// on tic
	onTic:HOOK_FUNCTION,
	onSelfHitOther:proc(self:^CharecterBase,other:^CharecterBase,world:^World,isCounter:bool,hitbox:Hit_box),
	// onBlocks
	onSelfBlocked:HOOK_FUNCTION,
	// onHit
	onSelfGotHit:HOOK_FUNCTION,
	// spawn projectile?
	selfSpawnProjectile:HOOK_FUNCTION,
	// onState change
	onSelfStateChange:proc(self:^CharecterBase,world:^World),
}

// RenderHooks :: struct {
// 	// on tic
// 	onTic:HOOK_FUNCTION,
// 	// onBlocks
// 	onSelfBlock:HOOK_FUNCTION,
// 	// onHit
// 	onSelfHit:HOOK_FUNCTION,
// 	// spawn projectile?
// 	spawnProjectile:HOOK_FUNCTION,
// 	// onState change
// 	onStateChange:HOOK_FUNCTION,
// }
