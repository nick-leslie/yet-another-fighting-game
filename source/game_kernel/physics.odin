package game_kernel

import "../../libs/jolt"
import "base:runtime"
import "core:log"
import rl "vendor:raylib"

PHYS_LAYER_MOVING :: jolt.ObjectLayer(0)
PHYS_LAYER_NON_MOVING :: jolt.ObjectLayer(1)
PHYS_LAYER_HURT_BOX :: jolt.ObjectLayer(2)
PHYS_LAYER_HIT_BOX :: jolt.ObjectLayer(3)

PHYS_BROAD_LAYER_MOVING :: jolt.BroadPhaseLayer(0)
PHYS_BROAD_LAYER_NON_MOVING :: jolt.BroadPhaseLayer(1)
PHYS_BROAD_LAYER_HURT_BOX :: jolt.BroadPhaseLayer(2) //todo do we want to seplrate this to p1/p2
PHYS_BROAD_LAYER_HIT_BOX :: jolt.BroadPhaseLayer(3)

Physics_Manager :: struct {
	jobSystem:                     ^jolt.JobSystem,
	physicsSystem:                 ^jolt.PhysicsSystem,
	objectLayerPairFilter:         ^jolt.ObjectLayerPairFilter,
	broadPhaseLayerFilter:         ^jolt.BroadPhaseLayerInterface,
	objectVsBroadPhaseLayerFilter: ^jolt.ObjectVsBroadPhaseLayerFilter,
	bodyInterface:                 ^jolt.BodyInterface,
	debugRenderer:                 ^jolt.DebugRenderer,
	fixed_update_accumulator:      f32,
}

// g_context: runtime.Context // should we store this
create_physics_mannager :: proc() -> Physics_Manager {
	ok := jolt.Init()
	log.debug(ok)
	assert(ok == true, "Failed to init Jolt Physics")
	context = runtime.default_context()
	jolt.SetTraceHandler(proc "c" (message: cstring) {
		context = runtime.default_context()
		log.debugf("JOLT: %v", message)
	})
	jobSystem := jolt.JobSystemThreadPool_Create(nil)

	object_layer_pair_filter := jolt.ObjectLayerPairFilterTable_Create(4)
	jolt.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		PHYS_LAYER_MOVING,
		PHYS_LAYER_NON_MOVING,
	)
	jolt.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		PHYS_LAYER_MOVING,
		PHYS_LAYER_MOVING,
	)
	jolt.ObjectLayerPairFilterTable_EnableCollision(
		object_layer_pair_filter,
		PHYS_LAYER_HURT_BOX,
		PHYS_LAYER_HIT_BOX,
	)

	broad_phase_layer_interface := jolt.BroadPhaseLayerInterfaceTable_Create(4, 4)
	jolt.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		PHYS_LAYER_MOVING,
		PHYS_BROAD_LAYER_MOVING,
	)
	jolt.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		PHYS_LAYER_NON_MOVING,
		PHYS_BROAD_LAYER_NON_MOVING,
	)
	jolt.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		PHYS_LAYER_HURT_BOX,
		PHYS_BROAD_LAYER_HURT_BOX,
	)
	jolt.BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
		broad_phase_layer_interface,
		PHYS_LAYER_HIT_BOX,
		PHYS_BROAD_LAYER_HIT_BOX,
	)

	object_vs_broad_phase_layer_filter := jolt.ObjectVsBroadPhaseLayerFilterTable_Create(
		broad_phase_layer_interface,
		4,
		object_layer_pair_filter,
		4,
	)
	physics_system := jolt.PhysicsSystem_Create(
		&{
			maxBodies = 65536,
			numBodyMutexes = 0,
			maxBodyPairs = 65536,
			maxContactConstraints = 65536,
			broadPhaseLayerInterface = broad_phase_layer_interface,
			objectLayerPairFilter = object_layer_pair_filter,
			objectVsBroadPhaseLayerFilter = object_vs_broad_phase_layer_filter,
		},
	)

	g_body_iface := jolt.PhysicsSystem_GetBodyInterface(physics_system)


	manager := Physics_Manager {
		jobSystem                     = jobSystem,
		objectLayerPairFilter         = object_layer_pair_filter,
		broadPhaseLayerFilter         = broad_phase_layer_interface,
		objectVsBroadPhaseLayerFilter = object_vs_broad_phase_layer_filter,
		bodyInterface                 = g_body_iface,
		physicsSystem                 = physics_system,
		debugRenderer                 = setup_debug_renderer(),
	}
	jolt.PhysicsSystem_SetGravity(physics_system, &[3]f32{0, -100, 0})
	return manager
}

setup_debug_renderer :: proc() -> ^jolt.DebugRenderer{
	@(static) debug_procs: jolt.DebugRenderer_Procs
	debug_procs = {
		DrawLine = proc "c" (userData: rawptr, from: ^[3]f32, to: ^[3]f32, color: jolt.Color) {
		    rl.DrawLine3D(to^,from^,rl.Color(color))
		},
		DrawTriangle = proc "c" (
			userData: rawptr,
			v1: ^jolt.RVec3,
			v2: ^jolt.RVec3,
			v3: ^jolt.RVec3,
			color: jolt.Color,
			castShadow: jolt.DebugRenderer_CastShadow,
		) {
		    rl.DrawTriangle3D(v1^,v2^,v3^,rl.Color(color))
		},
		DrawText3D = proc "c" (
			userData: rawptr,
			position: ^jolt.RVec3,
			str: cstring,
			color: jolt.Color,
			height: f32,
		) {
			context = runtime.default_context()
			assert(false, "Not implemented")
		},
	}
	renderer := jolt.DebugRenderer_Create(nil) // idk what to pass here pros context
	jolt.DebugRenderer_SetProcs(&debug_procs)
	return renderer
}

destroy_physics_mannager :: proc(physicsManager: ^Physics_Manager) {
	jolt.JobSystem_Destroy(physicsManager.jobSystem)
	jolt.PhysicsSystem_Destroy(physicsManager.physicsSystem)
	jolt.Shutdown()
}


add_floor :: proc(pm: ^Physics_Manager) -> jolt.BodyID {
	extent := FLOOR_EXTENT *0.5
	floor_shape := jolt.BoxShape_Create(&{f32(extent.x),f32(extent.y),f32(extent.z)}, 0)
	defer jolt.Shape_Destroy(auto_cast floor_shape)
	floor_settings := jolt.BodyCreationSettings_Create3(
		shape = auto_cast floor_shape,
		position = &{f32(FLOOR_POSITION.x),f32(FLOOR_POSITION.y),f32(FLOOR_POSITION.z)},
		rotation = &QUAT_IDENTITY,
		motionType = .Static,
		objectLayer = PHYS_LAYER_NON_MOVING,
	)
	floor_body_id := jolt.BodyInterface_CreateAndAddBody(
		pm.bodyInterface,
		floor_settings,
		.Activate,
	)
	jolt.BodyCreationSettings_Destroy(floor_settings)
	return floor_body_id
}
