class_name BandStats extends RefCounted
## How a band of players did together in a song.
##
## The band combo counts every note hit by any player and breaks when any player misses a note or
## lets go of a hold early. Wrong presses don't break it. It doesn't multiply any score.


## Each player's statistics, in player order.
var player_stats: Array[PerformanceStats]

## How many notes the band has hit in a row.
var combo := 0

## The highest [member combo] reached.
var longest_combo := 0

## The sum of the players' scores.
var total_score: int:
	get:
		var total := 0
		for stats: PerformanceStats in player_stats:
			total += stats.score
		return total


func _init(player_stats: Array[PerformanceStats]) -> void:
	self.player_stats = player_stats


## Record that a player hit a note.
func record_hit() -> void:
	combo += 1
	longest_combo = maxi(longest_combo, combo)


## Record that a player missed a note, or let go of a hold before its end.
func record_miss() -> void:
	combo = 0
