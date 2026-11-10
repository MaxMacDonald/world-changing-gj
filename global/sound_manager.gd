extends Node

const SOUND_FOLDER := "res://sounds/"

var _sounds:= {}
var _players: Array[AudioStreamPlayer]
var _next := 0
var _music: AudioStreamPlayer
var muted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # music runs even when game is paused

	# loading in the music file
	for file in ResourceLoader.list_directory(SOUND_FOLDER):
		if file.ends_with("/"): # skip subfile
			continue
		var stream := load(SOUND_FOLDER + file) as AudioStream
		if stream:
			_sounds[file.get_basename()] = stream
	for i in 12: # handle 12 sounds max concurrently
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
		
	_music = AudioStreamPlayer.new()
	add_child(_music) # add to scene tree
		
	# # testing
	# print("Sound: loaded ", _sounds.keys())
	# play("Button")
	# play_music("Tower defense chill")

# function to play the sound effect
func play(sound_name: String, volume_db := 0.0, pitch_variation := 0.0) -> void:
	if muted:
		return
	if not _sounds.has(sound_name): # check if audio exist
		push_warning("Sound: no sound file such as '%s'" %sound_name)
		return
	var player := _players[_next] # play the next audio in the queue
	_next = (_next + 1)% _players.size() # cyclical
	player.stream = _sounds[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()

# function to play the bgm
func play_music(sound_name: String) -> void:
	if not _sounds.has(sound_name): # check if audio exist
		push_warning("Sound: no sound file such as '%s'" %sound_name)
		return
	var stream: AudioStream = _sounds[sound_name]
	
	# check if the song is already playing
	# if so do nth so it won't get cut off
	if _music.stream == stream and _music.playing:
		return
	if "loop" in stream: # checks if audio is a loop(ogg not wav)
		stream.loop = true
	# load music into the speaker 
	_music.stream = stream
	_music.volume_db = -6.0
	_music.play()
	
# cut the music off 
func stop_music() -> void:
	_music.stop()

func stop_all_sfx() -> void:
	for player in _players:
		player.stop()
