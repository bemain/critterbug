extends Node
## What has happened in the story during this session, as named flags that dialogue reads and
## sets. A dialogue file can use any flag name without code: [code]if flag("met_snail")[/code] and
## [code]do set_flag("met_snail")[/code]. Later, songs will set flags too.
##
## The flags last until the game closes; saving them is for later.

var _flags: Dictionary[String, Variant] = {}


## The value of flag [param flag_name], or [code]false[/code] if it was never set.
func flag(flag_name: String) -> Variant:
	return _flags.get(flag_name, false)


## Set flag [param flag_name] to [param value].
func set_flag(flag_name: String, value: Variant = true) -> void:
	_flags[flag_name] = value
