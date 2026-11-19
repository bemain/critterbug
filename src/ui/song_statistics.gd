extends Control

signal back_pressed()


func _ready() -> void:
	visibility_changed.connect(_focus_back)
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", COLUMN_GAP)
	_columns.alignment = BoxContainer.ALIGNMENT_CENTER
	_columns.hide()
	$VBoxContainer.add_child(_columns)
	$VBoxContainer.move_child(_columns, $VBoxContainer/SongTitle.get_index() + 1)
	_band = Label.new()
	_band.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_band.add_theme_font_size_override("font_size", 24)
	_band.hide()
	$VBoxContainer.add_child(_band)
	$VBoxContainer.move_child(_band, $VBoxContainer/BackButton.get_index())


## Focus the Back button, so a gamepad or the keyboard can leave the screen.
func _focus_back() -> void:
	if is_visible_in_tree():
		$VBoxContainer/BackButton.grab_focus()


## Shows each player's results side by side when there are two or more players.
var _columns: HBoxContainer
## Shows the band's results when there are two or more players.
var _band: Label

## The gap between the players' columns, in pixels.
const COLUMN_GAP := 48


## Display the results of the [param players] and their [param band]. One player's results are shown
## alone, as they always were; two or more get a column each, and the band's results under them.
func load_results(players: Array[Player], band: BandStats) -> void:
	var is_band := players.size() >= 2
	for single in [$VBoxContainer/InstrumentName, $VBoxContainer/Difficulty, $VBoxContainer/PercentageHit,
			$VBoxContainer/PercentageHitHint, $VBoxContainer/Score, $VBoxContainer/LongestCombo,
			$VBoxContainer/Judgements]:
		single.visible = not is_band
	_columns.visible = is_band
	_band.visible = is_band
	load_stats(players[0].stats)
	if not is_band:
		return
	for column in _columns.get_children():
		column.queue_free()
	for i in players.size():
		_columns.add_child(_player_column(i + 1, players[i].stats))
	_band.text = "Band total: %d\nLongest band combo: %d" % [band.total_score, band.longest_combo]


## A column with what one player sees on their own: who they are, their part and level, and how
## they did.
func _player_column(number: int, stats: PerformanceStats) -> VBoxContainer:
	var counts := stats.judgement_counts
	var column := VBoxContainer.new()
	for text: String in [
		"P%d" % number,
		stats.part.name.capitalize(),
		_difficulty_text(stats),
		"%.1f%% hit" % (stats.fraction_notes_hit * 100),
		"Score: %d" % stats.score,
		"Longest combo: %d" % stats.longest_combo,
		"Perfect %d" % counts[Scoring.Judgement.PERFECT],
		"Good %d" % counts[Scoring.Judgement.GOOD],
		"Miss %d" % counts[Scoring.Judgement.MISS],
	]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
	return column


## Display the given [param stats] of one player.
func load_stats(stats: PerformanceStats):
	var song := stats.part.song
	$VBoxContainer/SongTitle.text = song.title
	$VBoxContainer/InstrumentName.text = stats.part.name
	$VBoxContainer/Difficulty.text = _difficulty_text(stats)
	$VBoxContainer/PercentageHit.text = "%.1f%%" % (stats.fraction_notes_hit*100)
	$VBoxContainer/Score.text = "Score: %d" % stats.score
	$VBoxContainer/LongestCombo.text = "Longest combo: %d" % stats.longest_combo
	var counts := stats.judgement_counts
	$VBoxContainer/Judgements.text = "Perfect %d · Good %d · Miss %d" % [
		counts[Scoring.Judgement.PERFECT],
		counts[Scoring.Judgement.GOOD],
		counts[Scoring.Judgement.MISS],
	]


## The difficulty played: its name, or for Auto the range of levels the song covered.
static func _difficulty_text(stats: PerformanceStats) -> String:
	var lowest: String = Difficulty.Level.keys()[stats.lowest_difficulty].capitalize()
	var highest: String = Difficulty.Level.keys()[stats.highest_difficulty].capitalize()
	if not stats.is_adaptive:
		return highest
	if lowest == highest:
		return "Auto: %s" % highest
	return "Auto: %s to %s" % [lowest, highest]


func _on_back_button_pressed() -> void:
	back_pressed.emit()
