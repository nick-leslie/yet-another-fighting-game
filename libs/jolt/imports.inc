when ODIN_OS == .Windows {
	foreign import lib "joltcd.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "libjoltcd.dylib"
} else when ODIN_OS == .Linux {
	foreign import lib "libjoltcd.so"
}
