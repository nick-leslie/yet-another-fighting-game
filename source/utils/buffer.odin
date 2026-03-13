package utils
@(require) import "core:log"

Buffer :: struct($N:int,$T:typeid) {
    buffer:[N]T,
    index:int,
}

FrameTrackedBuffer :: struct($N:int,$T:typeid) {
    using inner:Buffer(N,T),
    current_frame:int,
}

push :: proc(buffer:^Buffer($N,$T),item:T) {
    buffer.buffer[input_buffer.index] = input
    buffer.index += 1
    buffer.index = input_buffer.index %% len(input_buffer.buffer)
}

insert_at_frame :: proc(buffer:^FrameTrackedBuffer($N,$T),item:T,frame:int) {
    //pushing back into the past
    ensure(buffer.current_frame-frame <= len(buffer.buffer),"you cant push too far back into the past")
    buffer.index = frame %% len(buffer.buffer)
    buffer.current_frame = frame
    buffer.buffer[buffer.index] = item
}

get_at_frame :: proc(buffer:FrameTrackedBuffer($N,$T),frame:int) -> T {
    ensure(buffer.current_frame-frame <= cap(buffer.buffer),"you cant search back further than the frame requires")
    index := frame %% N
    return buffer.buffer[index]
}
