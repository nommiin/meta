# meta
A GameMaker 2.3 extension that allows for runtime asset inspection, intended to fill in the gaps for asset-related functions that might be missing.<br>
**This extension is still heavily in development and is subject to changes and additions.<br>Additionally, due to the nature of this extension; runtime updates can break chunk parsing. At the current time of development, this extension targets runtimes 23.1.1.160 through 23.1.1.166**

# Functions
## sprite_get_bbox_mode
```js
/// @function sprite_get_bbox_mode(ind)
/// @description Retrieves the mode (shape) of the given sprite
/// @argument {number} ind The index of the sprite
/// @returns sprite_bbox_mode macro (auto, full, manual)
```

## sprite_get_bbox_type
```js
/// @function sprite_get_bbox_type(ind)
/// @description Retrieves the type of collisions the sprite performs
/// @argument {number} ind The index of the sprite
/// @returns {number} sprite_bbox_type macro (rect, precise, rectrot)
```

## object_get_children
```js
/// @function object_get_children(ind)
/// @description Creates an array of all children belonging to the given object
/// @argument {number} ind The index of the object
/// @returns {array} Array containing object indices of all children
```
## audio_sound_get_audiogroup
```js
/// @function audio_sound_get_audiogroup(ind)
/// @description Retrieves the name of the audiogroup that a sound belongs to
/// @argument {number} ind The index of the sound
/// @returns {string} The name of the audiogroup for the sound
```

## sequence_get_name
```js
/// @function sequence_get_name(ind)
/// @description Retrieves the name of a given sequence
/// @argument {number} ind The index of the sequence
/// @returns {string} The name of the sequence
```

# Parsers
meta's modular nature allows for you to easily create your own chunk parsers to handle any missing asset types. For reference, you can refer to the ChunkHandler class of my other project "[Luna](https://github.com/nommiin/Luna/blob/master/Luna/Data/ChunkHandler.cs)" to find the structure of some chunks. To create your own parser, follow the below steps:
1. Add the 4-character chunk name into the global.\_\_metaHandlers\_\_.Order array<br>(**NOTE**: Be sure to keep in mind the order of chunk parsing, you usually don't want to parse any chunks before the *STRG* chunk is parsed)
2. Create a static method for the global.\_\_metaHandlers\_\_ class that parses the binary chunk
3. Add any functions to retireve different information for the new chunk
