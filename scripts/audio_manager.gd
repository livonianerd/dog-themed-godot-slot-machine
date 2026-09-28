extends Node
var music := AudioStreamPlayer.new()
var effects: Array[AudioStreamPlayer] = []
var settings: Dictionary
var started := false
var current := ""
func _ready():
	add_child(music)
	music.finished.connect(func():
		if started: music.play())
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
func interact(s: Dictionary):
	settings = s
	started = true
	apply(s)
func apply(s: Dictionary, free_mode: bool = false):
	settings = s
	music.volume_db = linear_to_db(0.0 if s.mute else float(s.music))
	var track := "free" if free_mode else ("meadow" if s.theme == 0 else "snow")
	if track != current or not music.playing:
		current = track
		music.stream = load("res://assets/audio/" + track + ".wav")
		if started: music.play()
func play_sound(name: String):
	if not started or settings.mute: return
	if settings.reduced_sound and name in ["spin", "bark", "howl", "click"]: return
	for player in effects:
		if not player.playing:
			player.stream = load("res://assets/audio/" + name + ".wav")
			player.volume_db = linear_to_db(float(settings.sfx))
			player.play()
			return
func _exit_tree():
	started=false
	music.stop()
	music.stream=null
	for player in effects:
		player.stop()
		player.stream=null
