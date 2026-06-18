package game

import gk "./game_kernel"

MAX_INPUTS :: (ROUND_DURATION_SECONDS * 60) * 2 // 60 inputs a second per user
Replay :: struct{
    round_inputs: [MAX_INPUTS]gk.Input,
    current_frame:i64,
    replay_ends_at:i64,
}


add_input :: proc(replay:^Replay,p1_input:gk.Input,p2_input:gk.Input) {
    replay.round_inputs[replay.current_frame] = p1_input
    replay.round_inputs[replay.current_frame+1] = p2_input
    replay.current_frame += 2 // each frame is 2 inputs
}

//todo do we want to only save rounds
save_replay :: proc(replay:Replay, path: string) {
    //todo do we want to run length encode

}
