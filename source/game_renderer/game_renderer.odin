package game_renderer
import rl "vendor:raylib"
import gk "../game_kernel"

//I realy need to get a 3d model and animations to start this module
Charecter3D :: struct($CU:typeid) {
   	model: 		rl.Model,
	animations: [^]rl.ModelAnimation,
	animation_count:i32,
	char_prt: ^gk.CharecterBase(CU)
}
