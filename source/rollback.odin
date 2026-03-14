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
RollbackStateQueue ::struct {
    //todo note to future nick use an option to show if there state there
    buffer:     [MAX_ROLLBACK_WINDOW]RollbackState,
    current_index:int,
    prev_index:int,
    current_frame:int,
    arena_backing:vmem.Arena,
    p1_input_mannager:^InputMannager,
    p2_input_mannager:^InputMannager,
}

create_new_rollback_queue :: proc(p1_input_mannager:^InputMannager,p2_input_mannager:^InputMannager,) -> RollbackStateQueue {
	arena: vmem.Arena
	//todo shrink me
	err := vmem.arena_init_growing(&arena, MAX_ROLLBACK_WINDOW*mem.Kilobyte) // todo grow this
	if err != nil {
		assert(false,"failed to make rollback state")
	}
	state_queue := RollbackStateQueue{
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

free_rollback_state_queue :: proc(queue:^RollbackStateQueue	) {
	vmem.arena_destroy(&queue.arena_backing)
}

DEBUG_ROLLBACK_FRAMES :: 7
//icrement current frame
add_new_state :: proc(queue:^RollbackStateQueue,world:gk.World,inputs:[2]gk.Input) {
    queue.current_frame+=1
    index :=  queue.current_frame % (len(queue.buffer)) // rollback windwo
    queue.current_index = index
    old := &queue.buffer[index]
    arena := &old.arena
    vmem.arena_free_all(arena)
    allocator := vmem.arena_allocator(arena)
	state := RollbackState {
		arena = old.arena,
        p1_input=inputs[0],
        p2_input=inputs[1],
        world_state =  gk.serlize_world(g.world,allocator),
        frame_number = queue.current_frame,
   	}
    queue.buffer[queue.current_index] = state
    //todo pop the state
}


get_current_state :: proc(queue:^RollbackStateQueue) -> RollbackState {
    return queue.buffer[queue.current_index]
}

rollback_too :: proc(queue:^RollbackStateQueue,back_too_frame:int) -> (int) {
    go_to :=  queue.current_frame
    queue.current_frame = back_too_frame
    queue.current_index = queue.current_frame %% len(queue.buffer) // rollback windwo
    return go_to
}

counter:=0

debug_rollback :: proc(queue:^RollbackStateQueue,frames:int) {
	if queue.current_frame < frames {
		log.debug("not enough frames to rollback skipping")
		return
	}
    go_too :=  rollback_too(queue,queue.current_frame-(frames))
    resimulate_rest(go_too,queue.current_frame)
}
//this shit is all cringe rewrite
resimulate_rest :: proc(go_too:int,frame:int) {
	frame := frame
    for g.rollback_state.current_frame != go_too {
        world_state := get_current_state(&g.rollback_state)
        //to try this
        p1_input := get_input_at_frame(g.rollback_state.p1_input_mannager,frame)
        p2_input := get_input_at_frame(g.rollback_state.p2_input_mannager,frame)
        gk.deserlize_world(world_state.world_state,&g.world)
       	gk.world_tic(&g.world,p1_input,p2_input)
       	gk.world_physics_tic(&g.world)
       	add_new_state(&g.rollback_state,g.world,[2]gk.Input{p1_input,p2_input})
        frame+=1
    }
}

rollback_correct_frame :: proc(frame:int,p1_input:gk.Input,p2_input:gk.Input) {
    go_too :=  rollback_too(&g.rollback_state,frame)
    world_state := get_current_state(&g.rollback_state)
    gk.deserlize_world(world_state.world_state,&g.world)
   	gk.world_tic(&g.world,p1_input,p2_input)
   	gk.world_physics_tic(&g.world)
   	add_new_state(&g.rollback_state,g.world,[2]gk.Input{p1_input,p2_input})
    resimulate_rest(go_too,frame)
}



// go back to frame
// correct input
// predict input
