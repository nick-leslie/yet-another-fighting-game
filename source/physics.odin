package game

import "../libs/jolt"
import "base:runtime"
import "core:log"

PHYS_LAYER_MOVING :: jolt.ObjectLayer(0)
PHYS_LAYER_NON_MOVING :: jolt.ObjectLayer(1)
PHYS_LAYER_HURT_BOX :: jolt.ObjectLayer(2)

PHYS_BROAD_LAYER_MOVING :: jolt.BroadPhaseLayer(0)
PHYS_BROAD_LAYER_NON_MOVING :: jolt.BroadPhaseLayer(1)
PHYS_BROAD_LAYER_HURT_BOX :: jolt.BroadPhaseLayer(2)

Physics_Manager :: struct {
	jobSystem:                     ^jolt.JobSystem,
	physicsSystem:                 ^jolt.PhysicsSystem,
	objectLayerPairFilter:         ^jolt.ObjectLayerPairFilter,
	broadPhaseLayerFilter:         ^jolt.BroadPhaseLayerInterface,
	objectVsBroadPhaseLayerFilter: ^jolt.ObjectVsBroadPhaseLayerFilter,
	bodyInterface:                 ^jolt.BodyInterface,
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

	object_layer_pair_filter := jolt.ObjectLayerPairFilterTable_Create(2)
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

	broad_phase_layer_interface := jolt.BroadPhaseLayerInterfaceTable_Create(2, 2)
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

	object_vs_broad_phase_layer_filter := jolt.ObjectVsBroadPhaseLayerFilterTable_Create(
		broad_phase_layer_interface,
		2,
		object_layer_pair_filter,
		2,
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
	}
	return manager
}

destroy_physics_mannager :: proc(physicsManager: ^Physics_Manager) {
	jolt.JobSystem_Destroy(physicsManager.jobSystem)
	jolt.PhysicsSystem_Destroy(physicsManager.physicsSystem)
	jolt.Shutdown()
}
