package game
import gk "game_kernel"
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

DEBUG_ROLLBACK_FRAMES :: 7
//icrement current frame
add_new_state :: proc(queue:^RollbackStateQueue,state:RollbackState) -> RollbackState {
    state := state
    queue.current_frame+=1
    state.frame_number = queue.current_frame
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
    go_too :=  rollback_too(&g.rollback_state,g.rollback_state.current_frame-(frames))
    resimulate_rest(go_too)

}

resimulate_rest :: proc(go_too:int) {
    for g.rollback_state.current_frame != go_too {
        world_state := get_current_state(&g.rollback_state)
        next_input := get_next_frame(&g.rollback_state)
        p1_input := next_input.p1_input
        p2_input := next_input.p2_input
        gk.deserlize_world(world_state.world_state,&g.world)
       	gk.world_tic(&g.world,p1_input,p2_input)
       	gk.world_physics_tic(&g.world)
        serlized_world_state := gk.serlize_world(g.world)
       	state := RollbackState {
                p1_input=p1_input,
                p2_input=p2_input,
                world_state =  serlized_world_state,
       	}
       	add_new_state(&g.rollback_state,state)
    }
}
predict_input :: proc() -> gk.Input {
    return gk.Input {
  		dir = gk.Direction.Neutral,
   	}
}
resimulate_frame :: proc(frame:int,remote_input:gk.Input,remote_p1:bool) {
    go_too :=  rollback_too(&g.rollback_state,frame)
    next_input := get_next_frame(&g.rollback_state)
    world_state := get_current_state(&g.rollback_state)
    p1_input := next_input.p1_input
    p2_input := next_input.p2_input
    if remote_p1 == true {
        p1_input = predict_input()
    } else {
        p2_input = predict_input()
    }
    gk.deserlize_world(world_state.world_state,&g.world)
   	gk.world_tic(&g.world,p1_input,p2_input)
   	gk.world_physics_tic(&g.world)
    serlized_world_state := gk.serlize_world(g.world)
   	state := RollbackState {
            p1_input=p1_input,
            p2_input=p2_input,
            world_state =  serlized_world_state,
   	}
   	add_new_state(&g.rollback_state,state)
    resimulate_rest(go_too)
}
