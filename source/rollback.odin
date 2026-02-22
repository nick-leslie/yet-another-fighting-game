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



add_new_state :: proc(queue:^RollbackStateQueue,state:RollbackState) -> RollbackState {
    state := state
    queue.current_frame+=1
    state.frame_number = queue.current_frame
    old := queue.buffer[queue.current_index]
    queue.current_index = queue.current_frame % MAX_ROLLBACK_WINDOW // rollback windwo
    queue.buffer[queue.current_index] = state
    return old
    //todo pop the state
}

get_current_state :: proc(queue:^RollbackStateQueue) -> RollbackState {
    return queue.buffer[queue.current_index]
}


rollback_too :: proc(queue:^RollbackStateQueue,back_too_frame:int) -> (RollbackState,int) {
    go_to :=  queue.current_frame
    queue.current_frame = back_too_frame
    queue.current_index = queue.current_frame % MAX_ROLLBACK_WINDOW // rollback windwo
    prev_state_index := (queue.current_frame-1) % MAX_ROLLBACK_WINDOW // rollback windwo
    return queue.buffer[prev_state_index],go_to
}
