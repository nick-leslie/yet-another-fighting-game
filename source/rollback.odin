package game
import gk "game_kernel"


// TODO ADD A UNIVERSAL AMOUNT OF DELAY
// SEND THE INPUT IMEDENTLY OVER NETWORK
// BUT DELAY THERE EXECUTION LOCALY BY 1-2f

RollbackState :: struct {
    p1_input:gk.Input,
    p2_input:gk.Input,
    world_state:gk.SerlizedWorld,
}

// MAX_ROLLBACK_FRAMES :: 25
RollbackStateQueue ::struct {
    //todo note to future nick use an option to show if there state there
    buffer:     [MAX_ROLLBACK_WINDOW]Maybe(RollbackState),
    current_frame:int,
    prev_frame:int,
    rollback_frames:int,
}



add_new_state :: proc(queue:^RollbackStateQueue,state:RollbackState) -> Maybe(RollbackState) {
    old := queue.buffer[queue.current_frame]
    queue.buffer[queue.current_frame] = state
    queue.prev_frame = queue.current_frame
    queue.current_frame +=1
    assert(queue.rollback_frames <= len(buffer_backing),"we cant rollback further than the buffer")
    if queue.current_frame >= queue.rollback_frames-1 {
        queue.current_frame=0
    }
    return old
    //todo pop the state
}

get_last_state :: proc(queue:^RollbackStateQueue) -> Maybe(RollbackState) {
    return queue.buffer[queue.prev_frame]
}

start_rollback_n_frames_back :: proc(queue:^RollbackStateQueue,last_good:int) -> Maybe(RollbackState) {
    last_good_frame := queue.buffer[last_good]
    queue.current_frame = last_good +1
    return last_good_frame
}
