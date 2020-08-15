// Runtime
switch (GM_runtime_version) {
	case "23.1.1.110": case "23.1.1.111":
	case "23.1.1.115": case "23.1.1.116": break;
	default: {
		repeat (4) show_debug_message("[WARNING]: meta does not support the runtime version '" + GM_runtime_version + "', unexpected errors may occur.");
		break;	
	}
}

// Globals
global.__metaBuffer__ = undefined;
global.__metaChunks__ = undefined;
global.__metaStrings__ = undefined;
global.__metaSprites__ = undefined;
global.__metaObjects__ = undefined;
global.__metaAudioGroups__ = undefined;
global.__metaSounds__ = undefined;
global.__metaSequences__ = undefined;

global.__metaHandlers__ = new (function() constructor {
	// Members
	static Order = ["STRG", "SPRT", "OBJT", "AGRP", "SOND", "SEQN"];
	
	// Handlers
	static STRG = function( _chunk ) {
		global.__metaStrings__ = ds_map_create();
		meta_kvp(global.__metaBuffer__, function( _buffer ) {
			buffer_seek(_buffer, buffer_seek_relative, 4);
			var _metaOffset = buffer_tell(_buffer);
			global.__metaStrings__[? _metaOffset + 4] = buffer_read(_buffer, buffer_string);
		});
	}
	
	static SPRT = function( _chunk ) {
		global.__metaSprites__ = ds_map_create();
		meta_kvp(global.__metaBuffer__, function( _buffer, _index ) {
			var _metaSprite = new meta_sprite(_buffer);
			global.__metaSprites__[? _index] = _metaSprite;
		});
	}
	
	static OBJT = function ( _chunk ) {
		global.__metaObjects__ = ds_map_create();
		meta_kvp(global.__metaBuffer__, function( _buffer, _index ) {
			var _metaObject = new meta_object(_buffer);
			global.__metaObjects__[? _index] = _metaObject;
		});
	}
	
	static AGRP = function( _chunk ) {
		global.__metaAudioGroups__ = [];
		meta_kvp(global.__metaBuffer__, function( _buffer, _index ) {
			global.__metaAudioGroups__[_index] = meta_string(_buffer);
		});
	}
	
	static SOND = function( _chunk ) {
		global.__metaSounds__ = ds_map_create();
		meta_kvp(global.__metaBuffer__, function( _buffer, _index ) {
			var _metaSound = new meta_sound(_buffer);
			global.__metaSounds__[? _index] = _metaSound;
		});
	}
	
	static SEQN = function( _chunk ) {
		buffer_seek(global.__metaBuffer__, buffer_seek_relative, 4); // ???
		global.__metaSequences__ = ds_map_create();
		meta_kvp(global.__metaBuffer__, function( _buffer, _index ) {
			var _metaSequence = new meta_sequence(_buffer);
			global.__metaSequences__[? _index] = _metaSequence;
		});
	}
	
	return self;
})();

// Constructors
function meta_chunk( _buffer ) constructor {
	self.Name = meta_nameof(_buffer);
	self.Length = buffer_read(_buffer, buffer_u32);
	self.Base = buffer_tell(_buffer);
	
	static toString = function() {
		return "Chunk: '" + self.Name + "', Length: " + string(self.Length) + " bytes";	
	}
}

function meta_sprite( _buffer ) constructor {
	self.Name = meta_string(_buffer);
	self.Width = buffer_read(_buffer, buffer_s32);
	self.Height = buffer_read(_buffer, buffer_s32);
	self.BoundsLeft = buffer_read(_buffer, buffer_s32);
	self.BoundsRight = buffer_read(_buffer, buffer_s32);
	self.BoundsBottom = buffer_read(_buffer, buffer_s32);
	self.BoundsTop = buffer_read(_buffer, buffer_s32);
	self.Transparent = buffer_read(_buffer, buffer_u32) == 1;
	self.Smooth = buffer_read(_buffer, buffer_u32) == 1;
	self.Preload = buffer_read(_buffer, buffer_u32) == 1;
	self.BoundsType = buffer_read(_buffer, buffer_u32);
	self.CollisionType = buffer_read(_buffer, buffer_u32);
}

function meta_object( _buffer ) constructor {
	self.Name = meta_string(_buffer);
	self.Sprite = buffer_read(_buffer, buffer_s32);
	self.Visible = buffer_read(_buffer, buffer_u32) == 1;
	self.Solid = buffer_read(_buffer, buffer_u32) == 1;
	self.Depth = buffer_read(_buffer, buffer_s32);
	self.Persistent = buffer_read(_buffer, buffer_u32) == 1;
	self.Parent = buffer_read(_buffer, buffer_s32);
	self.Mask = buffer_read(_buffer, buffer_s32);
}

function meta_sound( _buffer ) constructor {
	self.Name = meta_string(_buffer);
	self.Type = buffer_read(_buffer, buffer_u32);
	self.Extension = meta_string(_buffer);
	self.Filename = meta_string(_buffer);
	self.Effects = buffer_read(_buffer, buffer_u32);
	self.Volume = buffer_read(_buffer, buffer_f32);
	self.Pan = buffer_read(_buffer, buffer_f32);
	self.Group = global.__metaAudioGroups__[buffer_read(_buffer, buffer_u32)];
}

function meta_sequence( _buffer ) constructor {
	self.Name = meta_string(_buffer);
}

// Functions
function meta_init() {
	var _metaFile = undefined;
	for(var i = 0; i < parameter_count(); i++) {
		if (filename_ext(parameter_string(i)) == ".win") {
			_metaFile = parameter_string(i);
			break;
		}
	}
	
	if (_metaFile != undefined) {
		global.__metaChunks__ = ds_map_create();
		meta_parse(_metaFile);
	} else throw "Could not find the WAD file path.";
}

function meta_nameof( _buffer ) {
	var _chunkName = "";
	repeat (4) _chunkName += chr(buffer_read(_buffer, buffer_u8));
	return _chunkName;
}

function meta_parse( _path ) {
	global.__metaBuffer__ = buffer_load(_path);
	if (buffer_get_size(global.__metaBuffer__) > 0) {
		if (meta_nameof(global.__metaBuffer__) == "FORM") {
			var _dataLength = buffer_read(global.__metaBuffer__, buffer_u32);
			while (buffer_tell(global.__metaBuffer__) < buffer_get_size(global.__metaBuffer__)) {
				var _metaChunk = new meta_chunk(global.__metaBuffer__);
				global.__metaChunks__[? _metaChunk.Name] = _metaChunk;
				buffer_seek(global.__metaBuffer__, buffer_seek_relative, _metaChunk.Length);
			}
			
			for(var i = 0; i < array_length(global.__metaHandlers__.Order); i++) {
				var _chunkName = global.__metaHandlers__.Order[i], _chunkGet = global.__metaChunks__[? _chunkName];
				if (_chunkGet != undefined && variable_struct_exists(global.__metaHandlers__, _chunkName) == true) {
					buffer_seek(global.__metaBuffer__, buffer_seek_start, _chunkGet.Base);
					variable_struct_get(global.__metaHandlers__, _chunkName)(_chunkGet);
				}
			}
		} else throw "Could not parse WAD file, invalid header.";
	} else throw "Could not parse WAD file, size is 0.";
}

function meta_string( _buffer ) {
	return global.__metaStrings__[? buffer_read(_buffer, buffer_u32) + 4];
}

function meta_kvp( _buffer, _handler, _index ) {
	var _metaCount = buffer_read(_buffer, buffer_u32);
	for(var i = 0; i < _metaCount; i++) {
		var _metaOffset = buffer_read(_buffer, buffer_u32), _metaBase = buffer_tell(_buffer);
		buffer_seek(_buffer, buffer_seek_start, _metaOffset);
		_handler(_buffer, i);
		buffer_seek(_buffer, buffer_seek_start, _metaBase);
	}
}

meta_init();
buffer_delete(global.__metaBuffer__);

// Extension
/// @function sprite_get_bbox_mode(ind)
/// @description Retrieves the mode (shape) of the given sprite
/// @argument {number} ind The index of the sprite
/// @returns sprite_bbox_mode macro (auto, full, manual)
function sprite_get_bbox_mode(ind) {
	#macro sprite_bbox_mode_auto 0
	#macro sprite_bbox_mode_full 1
	#macro sprite_bbox_mode_manual 2
	var _metaSprite = global.__metaSprites__[? ind];
	if (_metaSprite != undefined) {
		return _metaSprite.BoundsType;
	} else throw "Could not find sprite with index '" + string(ind) + "'.";
}

/// @function sprite_get_bbox_type(ind)
/// @description Retrieves the type of collisions the sprite performs
/// @argument {number} ind The index of the sprite
/// @returns {number} sprite_bbox_type macro (rect, precise, rectrot)
function sprite_get_bbox_type(ind) {
	#macro sprite_bbox_type_rect 0
	#macro sprite_bbox_type_precise 1
	#macro sprite_bbox_type_rectrot 2
	var _metaSprite = global.__metaSprites__[? ind];
	if (_metaSprite != undefined) {
		return _metaSprite.CollisionType;
	} else throw "Could not find sprite with index '" + string(ind) + "'.";
}

/// @function object_get_children(ind)
/// @description Creates an array of all children belonging to the given object
/// @argument {number} ind The index of the object
/// @returns {array} Array containing object indices of all children
function object_get_children(ind) {
	var _metaChildren = [];
	for(var i = ds_map_find_first(global.__metaObjects__); i != undefined; i = ds_map_find_next(global.__metaObjects__, i)) {
		if (global.__metaObjects__[? i].Parent == ind) {
			_metaChildren[array_length(_metaChildren)] = i;
		}
	}
	return _metaChildren;
}

/// @function audio_sound_get_audiogroup(ind)
/// @description Retrieves the name of the audiogroup that a sound belongs to
/// @argument {number} ind The index of the sound
/// @returns {string} The name of the audiogroup for the sound
function audio_sound_get_audiogroup(ind) {
	var _metaSound = global.__metaSounds__[? ind];
	if (_metaSound != undefined) {
		return _metaSound.Group;
	} else throw "Could not find sound with index '" + string(ind) + "'."
}

/// @function sequence_get_name(ind)
/// @description Retrieves the name of a given sequence
/// @argument {number} ind The index of the sequence
/// @returns {string} The name of the sequence
function sequence_get_name(ind) {
	var _metaSequence = global.__metaSequences__[? ind];
	if (_metaSequence != undefined) {
		return _metaSequence.Name;
	} else throw "Could not find sequence with index '" + string(ind) + "'.";
}
