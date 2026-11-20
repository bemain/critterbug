extends Control


@onready var song_manager: SongManager = $"../SongManager"

## Shows the band combo during a song with two or more players.
var _band_combo: Label

## Where the players join and choose their parts, after the song is chosen.
var _join_screen: JoinScreen


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
	_join_screen = JoinScreen.new()
	_join_screen.hide()
	add_child(_join_screen)
	_join_screen.started.connect(_on_join_screen_started)
	_join_screen.back_pressed.connect(_on_join_screen_back_pressed)


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


## Leaving Free play: everyone who joined leaves too.
func _on_song_selection_menu_back_pressed() -> void:
	$SongSelectionMenu.hide()
	_join_screen.clear()
	$MainMenu.show()


func _on_song_selection_menu_song_selected(song: Song) -> void:
	$SongSelectionMenu.hide()
	_join_screen.open(song)


func _on_join_screen_back_pressed() -> void:
	_join_screen.hide()
	$SongSelectionMenu.show()


func _on_join_screen_started(players: Array[Player]) -> void:
	_join_screen.hide()
	song_manager.play(players)


func _on_song_manager_song_finished(song: Song) -> void:
	$SongStatistics.load_results(song_manager.players, song_manager.band)
	$SongStatistics.show()


## Back to the join screen for the same song, so the band can play again or change parts.
func _on_song_statistics_back_pressed() -> void:
	$SongStatistics.hide()
	_join_screen.open(_join_screen.song)
