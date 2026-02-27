package game
import gk "game_kernel"
import "core:log"
// import "core:log"


// TODO ADD A UNIVERSAL AMOUNT OF DELAY
// SEND THE INPUT IMEDENTLY OVER NETWORK
// BUT DELAY THERE EXECUTION LOCALY BY 1-2f

RollbackState :: struct {
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
}


//icrement current frame
add_new_state :: proc(queue:^RollbackStateQueue,state:RollbackState) -> RollbackState {
    state := state
    queue.current_frame+=1
    // state.frame_number = queue.current_frame
    queue.current_index = queue.current_frame % (len(queue.buffer)) // rollback windwo
    old := queue.buffer[queue.current_index]
    queue.buffer[queue.current_index] = state
    return old
    //todo pop the state
}

get_next_frame :: proc(queue:^RollbackStateQueue) -> RollbackState {
    frame :=queue.current_frame+1
    index := frame % (len(queue.buffer)) // rollback windwo
    return queue.buffer[index]
}

get_current_state :: proc(queue:^RollbackStateQueue) -> RollbackState {
    return queue.buffer[queue.current_index]
}

rollback_too :: proc(queue:^RollbackStateQueue,back_too_frame:int) -> (int) {
    go_to :=  queue.current_frame
    queue.current_frame = back_too_frame
    queue.current_index = queue.current_frame % len(queue.buffer) // rollback windwo
    return go_to
}

counter:=0

debug_rollback :: proc(frames:int) {
    pre_rollback_frame := g.rollback_state.current_frame
    pre_rollback_index := g.rollback_state.current_index
    go_too :=  rollback_too(&g.rollback_state,g.rollback_state.current_frame-(frames-1))
    post_rollback_frame := g.rollback_state.current_frame
    post_rollback_index := g.rollback_state.current_index
    //todo this may be wrong
    log.debugf("go_too frame %d current frame %d pre rollback frame %d ",
        go_too,
        post_rollback_frame,
        pre_rollback_frame,
    )
    log.debugf("current index %d pre rollback index %d ",
        post_rollback_index,
        pre_rollback_index,
    )
    for g.rollback_state.current_frame != go_too {
        world_state := get_current_state(&g.rollback_state)
        test := get_next_frame(&g.rollback_state)
        p1_input := test.p1_input
        p2_input := test.p2_input
        gk.deserlize_world(world_state.world_state,&g.world)
       	gk.world_tic(&g.world,p1_input,p2_input)
       	gk.world_physics_tic(&g.world)
        serlized_world_state := gk.serlize_world(g.world)
       	state := RollbackState {
                p1_input=p1_input,
                p2_input=p2_input,
                world_state =  serlized_world_state,
       	}
        log.debug(g.rollback_state.current_index)
       	add_new_state(&g.rollback_state,state)
        log.debug(g.rollback_state.current_index)
        log.debug("---")
    }
    complete_rollback_index := g.rollback_state.current_index
    complete_rollback_frame := g.rollback_state.current_frame
    log.debugf("rollback complete index %d frame:%d",complete_rollback_index,complete_rollback_frame)
    if counter < 15 {
        counter+=1
    } else {
        // assert(false)
    }
}


// 1 2 3 4 5 6 7 8 9 10
// ^
