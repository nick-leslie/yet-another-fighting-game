package game
import gk "game_kernel"
import vmem "core:mem/virtual"
import "core:mem"
import "core:log"


// TODO ADD A UNIVERSAL AMOUNT OF DELAY
// SEND THE INPUT IMEDENTLY OVER NETWORK
// BUT DELAY THERE EXECUTION LOCALY BY 1-2f

RollbackState :: struct($C:typeid,$C2:typeid) {
	arena:vmem.Arena,
    p1_input:gk.Input,
    p2_input:gk.Input,
    world_state:gk.SerlizedWorld(C,C2),
    frame_number:int,
}

// MAX_ROLLBACK_FRAMES :: 25
RollbackMannager ::struct($C:typeid,$C2:typeid) {
    //todo note to future nick use an option to show if there state there
    buffer:     [MAX_ROLLBACK_WINDOW]RollbackState(C,C2),
    current_index:int,
    prev_index:int,
    current_frame:int,
    arena_backing:vmem.Arena,
    p1_input_mannager:^InputMannager,
    p2_input_mannager:^InputMannager,
}

create_new_rollback_queue :: proc(w:gk.World($C,$C2),p1_input_mannager:^InputMannager,p2_input_mannager:^InputMannager) -> RollbackMannager(C,C2) {
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
            world_state = gk.serlize_world(w,slot_allocator),
       	}
        state_queue.buffer[i] = state
	}
	log.debug("%d",state_queue.current_index)
	return state_queue
}

free_rollback_state_queue :: proc(queue:^RollbackMannager($C,$C2)) {
	vmem.arena_destroy(&queue.arena_backing)
}

DEBUG_ROLLBACK_FRAMES :: 7
//icrement current frame
save_current_world_state :: proc(queue:^RollbackMannager($C,$C2),world:gk.World(C,C2)) {
    queue.current_frame+=1
    index :=  queue.current_frame %% (len(queue.buffer)) // rollback windwo
    queue.current_index = index
    old := &queue.buffer[index]
    arena := &old.arena
    vmem.arena_free_all(arena)
    allocator := vmem.arena_allocator(arena)
	state := RollbackState(C,C2) {
		arena = arena^,
        world_state =  gk.serlize_world(g.world,allocator),
        frame_number = queue.current_frame,
   	}
    queue.buffer[queue.current_index] = state
    //todo pop the state
}


get_current_state :: proc(queue:^RollbackMannager($C,$C2)) -> RollbackState(C,C2) {
    return queue.buffer[queue.current_index]
}

rollback_too :: proc(queue:^RollbackMannager($C,$C2),back_too_frame:int) -> (int) {
    go_to :=  queue.current_frame
    queue.current_frame = back_too_frame
    queue.current_index = queue.current_frame %% len(queue.buffer) // rollback windwo
    return go_to
}

counter:=0

debug_rollback :: proc(rollback_mannager:^RollbackMannager($C,$C2),world:^gk.World(C,C2),frames:int) {
	if rollback_mannager.current_frame < frames {
		log.debug("not enough frames to rollback skipping")
		return
	}
    go_too :=  rollback_too(rollback_mannager,rollback_mannager.current_frame-(frames))
    resimulate_rest(rollback_mannager,world,go_too)
}

//this shit is all cringe rewrite
resimulate_rest :: proc(rollback_mannager:^RollbackMannager($C,$C2),world:^gk.World(C,C2),go_to:int) {
    for g.rollback_state.current_frame != go_to {
    	run_frame(rollback_mannager,world)
    }
}

rollback_correct_frame :: proc(rollback_mannager:^RollbackMannager($C,$C2),world:^gk.World(C,C2),frame:int) {
    go_too :=  rollback_too(rollback_mannager,frame)
    run_frame(rollback_mannager,world)
    resimulate_rest(rollback_mannager,world,go_too)
}


run_frame :: proc(rollback_mannager:^RollbackMannager($C,$C2),world:^gk.World(C,C2)) {

	world_state := get_current_state(rollback_mannager)
    gk.deserlize_world(world_state.world_state,world)

   	p1_input := get_input_at_frame(rollback_mannager.p1_input_mannager,rollback_mannager.current_frame)
    p2_input := get_input_at_frame(rollback_mannager.p2_input_mannager,rollback_mannager.current_frame)

   	gk.world_tic(world,p1_input,p2_input,rollback_mannager.current_frame)
   	gk.world_physics_tic(world)

   	save_current_world_state(rollback_mannager,world^)
}

// go back to frame
// correct input
// predict input
