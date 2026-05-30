extends Node

# We keep one dedicated player for music so it loops and doesn't overlap itself
var music_player = AudioStreamPlayer.new()

func _ready():
	# Add the music player to the manager when the game starts
	add_child(music_player)

# --- BACKGROUND MUSIC ---
func play_music(audio_stream: AudioStream):
	# If this exact song is already playing, don't restart it!
	if music_player.stream == audio_stream and music_player.playing:
		return
		
	music_player.stream = audio_stream
	music_player.play()

func stop_music():
	music_player.stop()

# --- SOUND EFFECTS (SFX) ---
func play_sfx(audio_stream: AudioStream, volume: float = 0.0):
	# Create a brand new audio player just for this sound
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = audio_stream
	sfx_player.volume_db = volume
	
	# Add it to the tree and play it
	add_child(sfx_player)
	sfx_player.play()
	
	# THE MAGIC TRICK: Tell the player to delete itself the exact millisecond the sound finishes!
	sfx_player.finished.connect(sfx_player.queue_free)
