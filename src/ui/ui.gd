extends Control


@onready var song_manager: SongManager = $"../SongManager"

## Shows the band combo during a song with two or more players.
var _band_combo: Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SongSelectionMenu.hide()
	$SongStatistics.hide()
	$SettingsMenu.hide()
	$MainMenu.show()
	_band_combo = Label.new()
	_band_combo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_band_combo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_band_combo.offset_top = 16
	_band_combo.add_theme_font_size_override("font_size", 24)
	_band_combo.hide()
	add_child(_band_combo)


func _process(_delta: float) -> void:
	var count_in_beat := song_manager.count_in_beat
	$CountIn.visible = count_in_beat > 0
	$CountIn.text = str(count_in_beat)
	_band_combo.visible = song_manager.playing and song_manager.players.size() >= 2
	if _band_combo.visible:
		_band_combo.text = "Band combo: %d" % song_manager.band.combo


func _on_main_menu_settings_pressed() -> void:
	$MainMenu.hide()
	$SettingsMenu.show()


func _on_settings_menu_back_pressed() -> void:
	$SettingsMenu.hide()
	$MainMenu.show()


func _on_main_menu_freeplay_pressed() -> void:
	$MainMenu.hide()
	$SongSelectionMenu.show()


func _on_song_selection_menu_back_pressed() -> void:
	$SongSelectionMenu.hide()
	$MainMenu.show()


func _on_song_selection_menu_part_selected(part: SongPart, difficulty: Difficulty.Level, is_adaptive: bool) -> void:
	$MainMenu.hide()
	$SongSelectionMenu.hide()


func _on_song_manager_song_finished(song: Song) -> void:
	$SongStatistics.load_results(song_manager.players, song_manager.band)
	$SongStatistics.show()


func _on_song_statistics_back_pressed() -> void:
	$SongStatistics.hide()
	$SongSelectionMenu.show()
