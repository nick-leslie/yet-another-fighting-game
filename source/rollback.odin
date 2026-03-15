package game
import gk "game_kernel"
import vmem "core:mem/virtual"
import "core:mem"
import "core:log"


// TODO ADD A UNIVERSAL AMOUNT OF DELAY
// SEND THE INPUT IMEDENTLY OVER NETWORK
// BUT DELAY THERE EXECUTION LOCALY BY 1-2f

RollbackState :: struct {
	arena:vmem.Arena,
    p1_input:gk.Input,
    p2_input:gk.Input,
    world_state:gk.SerlizedWorld,
    frame_number:int,
}

// MAX_ROLLBACK_FRAMES :: 25
RollbackMannager ::struct {
    //todo note to future nick use an option to show if there state there
    buffer:     [MAX_ROLLBACK_WINDOW]RollbackState,
    current_index:int,
    prev_index:int,
    current_frame:int,
    arena_backing:vmem.Arena,
    p1_input_mannager:^InputMannager,
    p2_input_mannager:^InputMannager,
}

create_new_rollback_queue :: proc(p1_input_mannager:^InputMannager,p2_input_mannager:^InputMannager,) -> RollbackMannager {
	arena: vmem.Arena
	//todo shrink me
	err := vmem.arena_init_growing(&arena, MAX_ROLLBACK_WINDOW*mem.Kilobyte) // todo grow this
	if err != nil {
		assert(false,"failed to make rollback state")
	}
	state_queue := RollbackMannager{
		p1_input_mannager=p1_input_mannager,
		p2_input_mannager=p2_input_mannager,
	}
	arena_allocator := vmem.arena_allocator(&arena)
	for i := 0 ; i < MAX_ROLLBACK_WINDOW; i+=1 {
		backing := make([]byte,mem.Kilobyte,arena_allocator)
		slot_arena: vmem.Arena

		static_err := vmem.arena_init_buffer(&slot_arena, backing[:])
		if static_err != nil {
			assert(false,"failed to make rollback state")
		}
		slot_allocator := vmem.arena_allocator(&arena)
    	state := RollbackState {
     		arena = slot_arena,
            world_state = gk.serlize_world(g.world,slot_allocator),
       	}
        state_queue.buffer[i] = state
	}
	log.debug("%d",state_queue.current_index)
	return state_queue
}

free_rollback_state_queue :: proc(queue:^RollbackMannager	) {
	vmem.arena_destroy(&queue.arena_backing)
}

DEBUG_ROLLBACK_FRAMES :: 7
//icrement current frame
add_new_state :: proc(queue:^RollbackMannager,world:gk.World) {
    queue.current_frame+=1
    index :=  queue.current_frame %% (len(queue.buffer)) // rollback windwo
    queue.current_index = index
    old := &queue.buffer[index]
    arena := &old.arena
    vmem.arena_free_all(arena)
    allocator := vmem.arena_allocator(arena)
	state := RollbackState {
		arena = old.arena,
        world_state =  gk.serlize_world(g.world,allocator),
        frame_number = queue.current_frame,
   	}
    queue.buffer[queue.current_index] = state
    //todo pop the state
}


get_current_state :: proc(queue:^RollbackMannager) -> RollbackState {
    return queue.buffer[queue.current_index]
}

rollback_too :: proc(queue:^RollbackMannager,back_too_frame:int) -> (int) {
    go_to :=  queue.current_frame
    queue.current_frame = back_too_frame
    queue.current_index = queue.current_frame %% len(queue.buffer) // rollback windwo
    return go_to
}

counter:=0

debug_rollback :: proc(rollback_mannager:^RollbackMannager,world:^gk.World,frames:int) {
	if rollback_mannager.current_frame < frames {
		log.debug("not enough frames to rollback skipping")
		return
	}
    go_too :=  rollback_too(rollback_mannager,rollback_mannager.current_frame-(frames))
    resimulate_rest(rollback_mannager,world,go_too)
}

//this shit is all cringe rewrite
resimulate_rest :: proc(rollback_mannager:^RollbackMannager,world:^gk.World,go_to:int) {
    for g.rollback_state.current_frame != go_to {
    	run_frame(rollback_mannager,world)
    }
}

rollback_correct_frame :: proc(rollback_mannager:^RollbackMannager,world:^gk.World,frame:int) {
    go_too :=  rollback_too(rollback_mannager,frame)
    run_frame(rollback_mannager,world)
    resimulate_rest(rollback_mannager,world,go_too)
}


run_frame :: proc(rollback_mannager:^RollbackMannager,world:^gk.World) {

	world_state := get_current_state(rollback_mannager)
    gk.deserlize_world(world_state.world_state,world)

   	p1_input := get_input_at_frame(rollback_mannager.p1_input_mannager,rollback_mannager.current_frame)
    p2_input := get_input_at_frame(rollback_mannager.p2_input_mannager,rollback_mannager.current_frame)
    nutral_input := gk.Input {dir=gk.Direction.Neutral}
    if p2_input == nutral_input {
    	assert(false,"found u")
    }
   	gk.world_tic(world,p1_input,p2_input)
   	gk.world_physics_tic(world)

   	add_new_state(rollback_mannager,world^)
}

// go back to frame
// correct input
// predict input
