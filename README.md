# Yet another fighting game Framework Yafg

The goal of this project was originaly to make a fighing game. However it has since evoloved 
into a framework. The project currently supports a fully deterministic game kernal. A framework for making new charecters. Rollback netcode. fixed point physics. More work is required for the full public version of this framework. 

## game kernel 
the game kernel is the core game engine. it currently supports charecters entitys, hit and hurt box detection. You Will need to modify the kernal for spesific rules of your game. however for more general things callback functions are exposed that must be filled in. 

### charecter base

### move

### pattern

# physics
This is the fixed floating point physics library. it has basic collision and vector adding. 

# rendering
Rendering is covered by raylib. it also covers loading of a assets.

# ui 
the ui is covered by clay.

# TODO. 
[ ] rollback top prio
* [x] input sync over network
* [x] 7 frame debug rollback.
* [x] state serlizable
* [ ] send acs
* [ ] Network debug functions delay+drop packet
* [x] Rollback on bad perdition
* [ ] ask for dropped input
* [x] better input queue and window
* [ ] serlize on validated that input is good.
* [ ] show that inputs are correct
* [ ] lobbys
* [ ] nat hole punch
* [ ] match making servers


[ ] menues
* [ ] title screen
* [ ] main menue
* [ ] charecter select

[ ] sound
* [ ] rollback proof sound
* [ ] fmod

[ ] gameplay/modes
* [ ] combo scalling
* [x] hook system
* [ ] local vs
* [ ] remote vs
* [ ] remaping controls 
* [ ] training mode
* [ ] replays
* [ ] replay moment tagging
* [ ] replay take over 
* [ ] replay highlights. tag when hits happen. cool combos. overwatch pog

[ ] quality of life/tools/misc
* [ ] hit box editor
* [ ] test replay system for combo validation

[ ] look and feel
* [ ] particals
* [ ] tag system for rendering. tag moves with info or tags for rendering. sutff like screen shake etc
* 

# early access and or beta
[ ] we have a main menue
[ ] we have 2 charecters
[ ] we have sound effects fmod
[ ] the game can be played online with rollback
[ ] basic training mode

# tools that could help
[ ] hit box editor
[ ] 


# nice to haves
[ ] music

# skills I need to learn
[ ] 3d moddeling
[ ] basic sound desighn




# goals for non prototype
* [ ] make charecters more generic. like how entitys work
* [x] rework physics remove jolt replace with custom
* [x] use fixed point
* [ ] add in a scripting lang for writing moves


future improvments 
* [ ] scripting lang support. lua,js,or custom
* [ ] modding tools. sends scripts and sprites over the net
