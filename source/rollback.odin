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
}

// MAX_ROLLBACK_FRAMES :: 25
RollbackStateQueue ::struct {
    //todo note to future nick use an option to show if there state there
    buffer:     [MAX_ROLLBACK_WINDOW]Maybe(RollbackState),
    current_frame:int,
    prev_frame:int,
}



add_new_state :: proc(queue:^RollbackStateQueue,state:RollbackState) -> Maybe(RollbackState) {
    old := queue.buffer[queue.current_frame]
    queue.buffer[queue.current_frame] = state
    queue.prev_frame = queue.current_frame
    queue.current_frame +=1
    if queue.current_frame >= MAX_ROLLBACK_WINDOW {
        queue.current_frame=0
    }
    return old
    //todo pop the state
}

get_last_state :: proc(queue:^RollbackStateQueue) -> Maybe(RollbackState) {
    return queue.buffer[queue.prev_frame]
}

start_rollback_n_frames_back :: proc(queue:^RollbackStateQueue,rollback_frame_count:int) -> (Maybe(RollbackState),int) {
    go_to :=  queue.current_frame
    queue.current_frame -= rollback_frame_count
    if  queue.current_frame < 0 {
         queue.current_frame=MAX_ROLLBACK_WINDOW + queue.current_frame // add in the amoubt past 0
    }
    if queue.current_frame != 0 {
        last_good_frame := queue.buffer[queue.current_frame]
        log.debug(queue.current_frame)
        return last_good_frame,go_to
    } else {
        last_good_frame := queue.buffer[MAX_ROLLBACK_WINDOW-1]
        log.debug(MAX_ROLLBACK_WINDOW-1)
        return last_good_frame,go_to
    }
}
