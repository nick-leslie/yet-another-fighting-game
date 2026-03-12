package utils

Buffer :: struct($N:int,$T:typeid) {
    buffer:[$N]$T,
    index:int,
    len:$N,
}

FrameTrackedBuffer :: struct($N:int,$T:typeid) {
    using buffer:Buffer(N,T),
    current_frame:int,
}

push :: proc(buffer:Buffer($N,$T),item:T) {
    buffer.buffer[input_buffer.index] = input
    buffer.index += 1
    buffer.index = input_buffer.index %% len(input_buffer.buffer)
}

insert_at_frame :: proc(buffer:FrameTrackedBuffer($N,$T),item:T,frame:int) {
    //pushing back into the past
    ensure(buffer.current_frame-frame <= buffer.len,"you cant push too far back into the past")
    buffer.index = frame %% len(input_buffer.buffer)
    buffer.current_frame = frame
    buffer.buffer[input_buffer.input_index] = item
}

get_at_frame :: proc(buffer:FrameTrackedBuffer($N,$T),frame:int) -> N {
    ensure(buffer.current_frame-frame <= buffer.len,"you cant search back further than the frame requires")
    ensure(buffer.current_frame-frame > buffer.len,"You cant go further into the future than the frame buffer currently allow")
    index := frame %% N
    return buffer.buffer[index]
}
