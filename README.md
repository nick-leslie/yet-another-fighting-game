# Yet another fighting game Framework Yafg

The goal of this project was originally to make a fighting game. However, it has since evolved into a framework. The project currently supports a fully deterministic game kernel. A framework for making new characters. Rollback netcode. fixed point physics. 

## game kernel 
The game kernel is the core game engine. It currently supports character entities and hit and hurt box detection. You will need to modify the kernel for the specific rules of your game. However, for more general things, callback functions are exposed that must be filled in. 

The game kernel should be fully deterministic and should only depend on the inputs coming in. 

### character base
The way that you add extra data to charecters is through the charecter union generic. Create a struct like below

```
Charecters :: struct {
    // put all the every charecter data here
    charecter_spesific_data: union {
        TestCharacterData, // create structs in this union for characters
    },
}
```

The major trade-off of this style is that you need to either hard-code in the hooks/callbacks. Or create a constructor like below.

```
make_no_cancel_proc :: proc($T: typeid) -> proc(char: T, cancel_index: int) -> bool {
    return proc(char: T, cancel_index: int) -> bool {
        return false
    }
}

```

### State
A state is a character state with frames. For example, walking is a state, punching is a state, dp is a state. Every state must have at least one frame. Frames will be used both for running state logic and updating character rendering. To transition between states, you need to pass the exit check. The exit check is a callback per frame. 

### pattern
Patterns are a list of inputs. They also include a priority, so inputs that have overlap will have a higher priority.

# physics
This is the fixed floating-point physics library. It has basic collision and vector addition. 

# rendering
Rendering is covered by raylib. Raylib also exposes open gl under the hood. If I am feeling extra motivated, I may swap to Vulkan .

# asset loading
All non-code assets should be placed in the /assets folder. raylib will handle the loading of models and sprites. FMOD may be used for sound.

# ui 
the ui is covered by clay. Clay is a render agnostic ui library. We will need to add controller support on top of it. 

# sound 
todo but hopefully we will use fmod. im going to begin integrating this soon.

### code style

# pointers and mutability
Pointers in function parameters should be used to show that a value is mutable. If you don't need the value to be mutated within the function, just pass it as a pointer. 

# memory and arenas
Arenas are continuous buffers of memory where objects of the same lifetime live. Ryan Fleury has a great blo poast about this.
https://www.dgtlgrove.com/p/untangling-lifetimes-the-arena-allocator
Each memory arena should be for a specific life cycle

## Game Arena 
Any allocation that lasts the entire runtime of the game

## Character arena
Any allocation that has the same life cycle as the character. This includes patterns, states, and entities. The character arena is not saved during rollbacks.

## Frame arena(temporary allocation)
This is where any memory that needs to last the duration of the frame should go.
This is cleared every frame.

# Jam Requirements
* [ ] A competitive versus game 
* [ ] That functions completely with just two players
* [ ] Which allows for 1v1 matches in a functional local versus
* [ ] With real-time interactions and movement
* [ ] Taking place in the same screen (no split-screen, no "one screen per player")
* [ ] With at least 2 playable characters
* [ ] With the goal of knocking out your opponent
* [ ] Has full keyboard support and (strongly recommended) controller support for every player. Implementing either split keyboard or controller + keyboard for local versus is a required feature
* [ ] And can run in windowed mode


# other goals
* [ ] we have sound effects fmod and potentaly music
* [ ] The game can be played online with rollback
* [ ] basic training mode
* [ ] three or four characters

[ ] rollback 
* [x] input sync over network
* [x] 7 frame debug rollback.
* [x] state serializable
* [x] send acs on inputs
* [x] Network debug functions delay+drop packet
* [x] Rollback on bad perdition
* [x] ack for dropped input
* [x] better input queue and window
* [ ] serialise once validated that input is good.
* [ ] send acks on all network events
* [ ] lobbies
* [ ] nat hole punch
* [ ] match-making servers


[ ] menus
* [ ] title screen
* [ ] main menu
* [ ] character select
* [ ] edtable controls 

[ ] sound
* [ ] rollback proof sound
* [ ] fmod

[ ] gameplay/modes
* [x] combo scaling
* [x] hook system
* [ ] local vs
* [ ] remote vs
* [ ] remapping controls 
* [ ] training mode
* [ ] replays
* [ ] replay moment tagging
* [ ] replay take over 
* [ ] replay highlights. tag when hits happen. cool combos. overwatch pog

[ ] quality of life/tools/misc
* [ ] hit box editor
* [ ] test replay system for combo validation

[ ] look and feel
* [ ] particles
* [ ] side effects for rendering things like particals and sounds
* 

# tools that could help
* [ ] hit box editor
* [ ] 


# nice to haves
[ ] music


future improvements 
* [ ] scripting lang support. lua,js,or custom
* [ ] modding tools. sends scripts and sprites over the net
