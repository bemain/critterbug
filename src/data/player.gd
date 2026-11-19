class_name Player extends RefCounted
## One person in the band: the part they play, at which difficulty, with which input devices, and
## how they are doing.


## In [member devices], stands for every device, including ones connected later.
const ANY_DEVICE := -2

## The devices this player plays with: [constant LaneInput.KEYBOARD], joypad device ids, or
## [constant ANY_DEVICE].
var devices: Array[int]

## The part this player plays.
var part: SongPart

## The difficulty the player starts at.
var difficulty: Difficulty.Level

## Whether the difficulty adapts to how the player does.
var is_adaptive: bool

## The player's results in the song being played.
var stats: PerformanceStats

## Judges the player's presses in the song being played.
var judge: Judge


func _init(devices: Array[int], part: SongPart, difficulty: Difficulty.Level, is_adaptive := false) -> void:
	self.devices = devices
	self.part = part
	self.difficulty = difficulty
	self.is_adaptive = is_adaptive


## Whether presses on [param device] are this player's.
func accepts(device: int) -> bool:
	return ANY_DEVICE in devices or device in devices


## Start a new playthrough of the [member part], with notes coming into play [param lead_time_s]
## before their time.
func start(lead_time_s: float) -> void:
	stats = PerformanceStats.new(part, difficulty, is_adaptive)
	judge = Judge.new(stats, lead_time_s)
