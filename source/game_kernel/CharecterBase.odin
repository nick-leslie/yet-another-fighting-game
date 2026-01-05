package game_kernel
import "../../libs/jolt"
import "base:runtime"
import "core:log"
import "core:math"
import "core:math/linalg"

// this is just a type alieas so I can define it in multiple places


CHARACTER_CAPSULE_HALF_HEIGHT: f32 : 2
CHARACTER_CAPSULE_RADIUS: f32 : 1


//rename to charecter base
CharecterBase :: struct {
	physics_character: ^jolt.CharacterVirtual, // should we sperate
	using position:    Vec3,
	input_buffer:      InputBuffer,
	move_dir:          Vec3,
	jump_requested:    bool,
	in_air:            bool,
	prev_position:     Vec3,
	jump_height:       f32,
	move_speed:        f32,
	air_move_speed:    f32,
	air_drag:          f32,
	addional_velocity: Vec3,
	p1_side:           bool,
	states:            [dynamic]State, // should this be state
	patterns:          [dynamic]Pattern,
	current_frame:     int,
	current_state:     int, // this is an index
	hit_stun_frames:   u32,
	hit_stun_index:    int, // we may replace this with a constent
	block_stun_frames: u32,
	block_stun_index:  int,
	charecter_flags:   u128, // lots of flags for various states.. tuble extc
}

//which is slower waking or resizing

setup_charecter :: proc(char: ^CharecterBase, pm: ^Physics_Manager) {
	setup_charecter_collison(char, pm)
}


setup_charecter_collison :: proc(char: ^CharecterBase, pm: ^Physics_Manager) {
	// capsule shape with origin at the bottom
	capsule_shape := jolt.RotatedTranslatedShape_Create(
		position = &{0, CHARACTER_CAPSULE_HALF_HEIGHT, 0},
		rotation = &QUAT_IDENTITY,
		// todo we can change the shape to be what ever we want
		shape = auto_cast jolt.CapsuleShape_Create(
			CHARACTER_CAPSULE_HALF_HEIGHT,
			CHARACTER_CAPSULE_RADIUS,
		),
	)

	settings: jolt.CharacterVirtualSettings; jolt.CharacterVirtualSettings_Init(&settings)
	settings.base.shape = auto_cast capsule_shape
	settings.innerBodyShape = auto_cast capsule_shape // "inner shape" that actually participates in physics (e.g. reacts to raycast and stuff)

	character := jolt.CharacterVirtual_Create(
		&settings,
		&char.position,
		&QUAT_IDENTITY,
		0,
		pm.physicsSystem,
	)
	//todo pass in context
	// use static var so the pointers survive
	@(static) listener_procs: jolt.CharacterContactListener_Procs
	listener_procs = {
		OnContactAdded = proc "c" (
			context_ptr: rawptr,
			character: ^jolt.CharacterVirtual,
			other_body_id: jolt.BodyID,
			_: jolt.SubShapeID,
			contact_point: ^Vec3,
			contact_normal: ^Vec3,
			contact_settings: ^jolt.CharacterContactSettings,
		) {
			//
			// if other_body_id == w.stage.floor_id do return
			// context = (cast(^runtime.Context)context_ptr)^

			// log.debugf("Contact added: %v", other_body_id)
		},
		OnContactPersisted = proc "c" (
			context_ptr: rawptr,
			character: ^jolt.CharacterVirtual,
			other_body_id: jolt.BodyID,
			_: jolt.SubShapeID,
			contact_point: ^Vec3,
			contact_normal: ^Vec3,
			contact_settings: ^jolt.CharacterContactSettings,
		) {
			// if other_body_id == w.stage.floor_id do return

			// context = (cast(^runtime.Context)context_ptr)^

			// log.debugf("Contact persisted: %v", other_body_id)
		},
		OnContactRemoved = proc "c" (
			context_ptr: rawptr,
			character: ^jolt.CharacterVirtual,
			other_body_id: jolt.BodyID,
			_: jolt.SubShapeID,
		) {
			// if other_body_id == w.stage.floor_id do return

			// context = (cast(^runtime.Context)context_ptr)^

			// log.debugf("Contact removed: %v", other_body_id)
		},
	}
	current_context := runtime.default_context()
	listener := jolt.CharacterContactListener_Create(&current_context)
	jolt.CharacterContactListener_SetProcs(&listener_procs)
	jolt.CharacterVirtual_SetListener(character, listener)
	char.physics_character = character
}



//todo this is an ordering update. because we do pickstate -> physics_update
charecter_update :: proc(character: ^CharecterBase, input: Input) {
	log.debug("in charecter update")
	character.jump_requested = false // should this be reset here
	character.move_dir = {}
	character.addional_velocity = {} // do we want to reset this here
	update_input_buffer(character, input)

	log.debug("getting current state")
	state,frame := charecter_get_current_state_frame(character^)
	proposed_state_index := pick_state(character.input_buffer, character.patterns)
	log.debug("done getting state")

	state_frame_len := len(state.frames)

	exit_check := frame.check_exit(character, proposed_state_index)
	//exit check has to be true and we have to be at the end. but if exit check is true we can end pre maturely
	if (character.current_frame >= state_frame_len && exit_check == true) || exit_check == true {
		state,frame = charecer_change_state(character,proposed_state_index)
		// log.debug("new state needed")
	}

	log.debug("finished picking state")
	if character.hit_stun_frames > 0 && character.current_state != character.hit_stun_index {
		state,frame =  charecer_change_state(character,character.hit_stun_index)
	} else if character.block_stun_frames > 0 && character.current_state != character.block_stun_index{
		state,frame = charecer_change_state(character,character.block_stun_index)
	}


	frame.on_frame(character) // run frame update
	character.current_frame += 1 // incrment the fraem by 1
	log.debug("done with charecter update")
}

charecer_change_state :: proc(character:^CharecterBase,state:int) -> (State,Frame) {
	character.current_state = state
	character.current_frame = 0
	character.jump_requested = false

	state := character.states[character.current_state]
	frame := state.frames[character.current_frame]
	return state,frame
}

charecter_get_current_state_frame :: proc(character: CharecterBase) -> (State, Frame) {
	state := character.states[character.current_state]
	frame_to_pick := character.current_frame
	state_frame_len := len(state.frames)
	if character.current_frame >= state_frame_len {
		frame_to_pick = state_frame_len - 1 // lock on the last frame if we can progress
	}
	frame := state.frames[frame_to_pick]
	return state, frame
}

//adds hurt and hit boxes
character_add_hurt_boxes :: proc(character: CharecterBase, pm: Physics_Manager) {
	_, frame := charecter_get_current_state_frame(character)

	for &hurt_box in frame.hurtbox_list {
		log.debug(hurt_box)
		id := jolt.Body_GetID(hurt_box.body)
		log.debug(id)
		position: Vec3 = character.position + hurt_box.position
		jolt.BodyInterface_AddBody(pm.bodyInterface, id, .Activate)
		jolt.BodyInterface_SetPosition(pm.bodyInterface, id, &position, .Activate)
	}
	log.debug("done adding hurt boxes")
	//todo add all the bodys to the simulation before searching for an attack.
	// this nees to be done in lockstep seprate from the charecter update
}

character_remove_hurt_boxes :: proc(character: CharecterBase, pm: Physics_Manager) {
	_, frame := charecter_get_current_state_frame(character)
	for &hurt_box in frame.hurtbox_list {
		id := jolt.Body_GetID(hurt_box.body)
		jolt.BodyInterface_RemoveBody(pm.bodyInterface, id)
	}
}
// may want to put this in moves
CharPtrArr :: ^[2]^CharecterBase
HitBoxCtx :: struct {
	charecters: CharPtrArr,
	hitbox:     ^Hit_box,
	world: 		^World,
}
//bruh this shit about to get funky
character_check_hit :: proc(characters: CharPtrArr, w:^World) {
	_, frame := charecter_get_current_state_frame(characters[0]^)
	for &hit_box in frame.hitbox_list {
		narrow_phase_query := jolt.PhysicsSystem_GetNarrowPhaseQuery(w.physicsManager.physicsSystem)
		extent := hit_box.extent * 0.5
		box_shape := jolt.BoxShape_Create(&extent, 0) // make sure this works
		defer jolt.Shape_Destroy(auto_cast box_shape)
		//todo we figured out the issue it was the offset
		pos := hit_box.position + characters[0].position
		transform := jolt.RMat4 {
			1.,
			0.,
			0.,
			pos.x,
			0.,
			1.,
			0.,
			pos.y,
			0.,
			0.,
			1.,
			pos.z,
			0,
			0,
			0,
			1.,
		}
		// log.debug(transform)
		bround_phase_filter := jolt.BroadPhaseLayerFilter_Create(characters[0])

		hit_box_context := HitBoxCtx {
			charecters = characters,
			hitbox     = &hit_box,
			world 	   = w,
		}

		jolt.NarrowPhaseQuery_CastShape2(
			query = narrow_phase_query,
			shape = auto_cast box_shape,
			worldTransform = &transform,
			direction = &{0, 0, 0},
			settings = &{
				base = {
					activeEdgeMode       = .CollideWithAll,
					collectFacesMode     = .CollectFaces, // check this
					collisionTolerance   = 1, // to tweek this
					penetrationTolerance = 1,
				},
				backFaceModeTriangles = .CollideWithBackFaces, // tood check this
				backFaceModeConvex = .CollideWithBackFaces,
				useShrunkenShapeAndConvexRadius = true, // tood check this
				returnDeepestPoint = false, // we dont need the deepst point an it costs
			}, // shape cast settings
			baseOffset = &{},
			collectorType = .AllHit,
			callback = proc "c" (hit_ctx_ptr: rawptr, result: ^jolt.ShapeCastResult) {

				context = g_context // todo fix me
				hit_ctx: ^HitBoxCtx = auto_cast (hit_ctx_ptr) //todo remove auto cast
				self := CharPtrArr(hit_ctx.charecters)[0]
				other := CharPtrArr(hit_ctx.charecters)[1]



				self_state, frameSelf := charecter_get_current_state_frame(self^)
				_, frameOther := charecter_get_current_state_frame(other^)
				// we may want to speed this up later by seperating to a p1 layer
				for &hurt_box in frameSelf.hurtbox_list {
					id := jolt.Body_GetID(hurt_box.body)
					if id == result.bodyID2 do return
				}

				if hit_ctx.world.stage.floor_id == result.bodyID2 do return // use layers to filter

				self_id := jolt.CharacterVirtual_GetInnerBodyID(self.physics_character)
				other_id := jolt.CharacterVirtual_GetInnerBodyID(other.physics_character)
				if self_id == result.bodyID2 do return
				if other_id == result.bodyID2 do return

				side_mod: f32 = 1.
				if other.p1_side == false do side_mod = -1.

				for &hurt_box in frameOther.hurtbox_list {
					id := jolt.Body_GetID(hurt_box.body)
					if id == result.bodyID2 {
						// log.debug(hurt_box)
						block := charecter_check_block(other)
						if block == false && other.hit_stun_frames == 0 && other.block_stun_frames == 0{
							pushback := hit_ctx.hitbox.hitPushback
							pushback.x *= side_mod
							other.addional_velocity += pushback
							other.hit_stun_frames = self_state.hitstun
							other.block_stun_frames=0
							//set in hit_stun
						} else if other.hit_stun_frames == 0 && other.block_stun_frames == 0 {
							// log.debug("blocking")
							pushback := hit_ctx.hitbox.blockPushback
							pushback.x *= side_mod
							other.addional_velocity += pushback
							other.block_stun_frames = self_state.blockstun

							other.hit_stun_index=0
						}
						//check if blocking and set to block or hit_stun
					}
				}
			},
			userData = &hit_box_context,
			broadPhaseLayerFilter = bround_phase_filter,
			objectLayerFilter = nil,
			bodyFilter = nil,
			shapeFilter = nil,
		)
	}
}

charecter_check_block ::proc(charecter:  ^CharecterBase) -> bool {
	input := charecter.input_buffer.buffer[charecter.input_buffer.input_index]
	#partial switch input.dir {
	case Direction.Back:
		return true
	case Direction.DownBack:
		return true
		// this is where we decide up back or down back
	case:
		return false
	}
}

charecter_physics_update :: proc(character: ^CharecterBase, w: ^World) {
	log.debug("removing hurt boxes")
	character_remove_hurt_boxes(character^, w.physicsManager) // remove the hurt boxes before running physics
	log.debug("done removing hurt boxes")
	character.prev_position = character.position
	jump_pressed := character.jump_requested
	if character.in_air && jump_pressed {
		jump_pressed = false // there is a better way to do this
	}
	// get up vector (and update it in the character struct just in case)
	// up_const := UP
	// log.debug(up_const)
	// up: Vec3; jolt.CharacterBase_GetUp(auto_cast character.physics_character, &up_const)

	log.debug("updating grounded velocity")
	log.debug(character.physics_character)
	// A cheaper way to update the character's ground velocity, the platforms that the character is standing on may have changed velocity
	jolt.CharacterVirtual_UpdateGroundVelocity(character.physics_character)
	log.debug("end update grounded velocity")
	ground_velocity: Vec3; jolt.CharacterBase_GetGroundVelocity(auto_cast character.physics_character, &ground_velocity)

	current_velocity: Vec3; jolt.CharacterVirtual_GetLinearVelocity(character.physics_character, &current_velocity)
	current_vertical_velocity := linalg.dot(current_velocity, UP) * UP

	new_velocity: Vec3
	log.debug("got grounded state")
	if jolt.CharacterBase_GetGroundState(auto_cast character.physics_character) == .OnGround {
		// Assume velocity of ground when on ground
		new_velocity = ground_velocity

		// Jump
		moving_towards_ground := (current_vertical_velocity.y - ground_velocity.y) < 0.1
		// log.debug(jump_pressed)
		if jump_pressed && moving_towards_ground {
			log.debug(character.jump_requested)
			log.debug(character.move_dir)
			new_velocity += character.jump_height * UP
		}
	} else {
		new_velocity = current_vertical_velocity
	}
	log.debug("middle of function")
	// Add gravity
	gravity: Vec3; jolt.PhysicsSystem_GetGravity(w.physicsManager.physicsSystem, &gravity)
	new_velocity += gravity * FIXED_STEP
	input := character.move_dir

	input.y = 0
	input = linalg.normalize0(input)
	if jolt.CharacterBase_IsSupported(auto_cast character.physics_character) == true {
		new_velocity += input * (character.move_speed)
		character.in_air = false
	} else {
		// preserve horizontal velocity
		character.in_air = true
		current_horizontal_velocity := current_velocity - current_vertical_velocity
		new_velocity += current_horizontal_velocity * character.air_drag
		new_velocity += input * character.air_move_speed
	}
	new_velocity += character.addional_velocity
	// set the velocity to the character
	jolt.CharacterVirtual_SetLinearVelocity(character.physics_character, &new_velocity)

	extended_settings := jolt.ExtendedUpdateSettings {
		stickToFloorStepDown             = {0, -0.5, 0},
		walkStairsStepUp                 = {0, 0.4, 0},
		walkStairsMinStepForward         = 0.02,
		walkStairsStepForwardTest        = 0.15,
		walkStairsCosAngleForwardContact = math.cos(math.to_radians_f32(75.0)),
		walkStairsStepDownExtra          = {},
	}
	// update the character physics (btw there's also CharacterVirtual_ExtendedUpdate with stairs support)
	log.debug("charecter virtual extened update")
	jolt.CharacterVirtual_ExtendedUpdate(
		character.physics_character,
		FIXED_STEP,
		&extended_settings,
		PHYS_LAYER_MOVING,
		w.physicsManager.physicsSystem,
		nil,
		nil,
	)

	// read the new position into our structure
	jolt.CharacterVirtual_GetPosition(character.physics_character, &character.position)

	log.debug("push contatcts")
	// if we're on the ground, try pushing currect contacts away
	if jolt.CharacterBase_GetGroundState(auto_cast character.physics_character) == .OnGround {
		for i in 0 ..< jolt.CharacterVirtual_GetNumActiveContacts(character.physics_character) {
			contact: jolt.CharacterVirtualContact; jolt.CharacterVirtual_GetActiveContact(character.physics_character, i, &contact)
			if contact.bodyB == w.stage.floor_id do continue
			if contact.motionTypeB == .Dynamic {
				PUSH_FORCE :: 100
				push_vector := -contact.contactNormal * PUSH_FORCE
				jolt.BodyInterface_AddImpulse2(
					w.physicsManager.bodyInterface,
					contact.bodyB,
					&push_vector,
					&contact.position,
				)
			}
		}
	}
}


delete_charecter :: proc(char: ^CharecterBase) {
	log.debug("delting charecers")
	// delete all moves
	for &state in char.states {
		delete_state(&state)
	}
	delete(char.states)
	for &pattern in char.patterns {
		delete_pattern(&pattern)
	}
	delete(char.patterns)
}
