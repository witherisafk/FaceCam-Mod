A silly mod that acts as a base for creating in-game sprites that react to what Isaac does. Requires a supported mod [(such as this one!)](https://steamcommunity.com/sharedfiles/filedetails/?id=3828789219) in order to do anything observable, and [ReactionAPI](https://steamcommunity.com/workshop/filedetails/?id=3096181411) for reacting to certain events! The capabilities of this mod include:

- In-game sprite which can be animated during an idle state and other specific events, such as when the player begins their first run of the current game instance, finds a quality 4 item, or dies
- Support for playing random or specific animations within a .anm2 file, or assigning multiple .anm2 files to the same event to be played at random
- Sound effects that can play during certain events
- Implementations that make it simple to create supported mods (check out [the code of mod linked above](https://github.com/witherisafk/LazyMattCam) to learn how to make one yourself!)
- Mod config menu settings, with their default values configurable by the supported mod

**NOTE: this mod has been updated to restructure how sprites / sound effects are loaded! If you are using this mod to create a face cam, please see the change log for more details!**

This mod is still in development as well, with various additional upcoming features planned, such as:

- Functionality for playing sound effects at random
- Support for creating reactions (animations/sound effects) for more events, such as dying, encountering items as certain characters, picking up items of specific qualities when Isaac has curse of the blind, and more!

If you have any suggestions or bugs to report for the mod, please open a new issue, or contact me through Discord at **witherisafk**
