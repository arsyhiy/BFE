extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()
