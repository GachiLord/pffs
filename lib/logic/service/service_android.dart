import 'package:audio_service/audio_service.dart';
import 'package:pffs/logic/state.dart';

class AudioHandler extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  // mix in default seek callback implementations

  late final PlayerState _player; // e.g. just_audio

  AudioHandler(PlayerState player) {
    _player = player;
    _init();
  }

  void _init() async {
    _player.completedStream.listen((v) async {
      if (_player.currentTrack != null && v) {
        playbackState.add(PlaybackState(
          // Which buttons should appear in the notification now
          controls: [
            MediaControl.skipToPrevious,
            v ? MediaControl.play : MediaControl.pause,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.ready,
          playing: true,
          speed: 1.0,
          queueIndex: _player.currentIndex,
        ));
        var item = MediaItem(
          id: _player.currentTrack!.relativePath,
          title: _player.currentTrack!.name,
          artist: _player.playlistName,
          duration: _player.duration,
          artUri: await _player.currentArtUri,
        );
        mediaItem.add(item);
      }
    });
    _player.playingStream.listen((v) async {
      if (_player.currentTrack != null) {
        playbackState.add(PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            v ? MediaControl.play : MediaControl.pause,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.ready,
          playing: v,
          speed: 1.0,
          // The current queue position
          queueIndex: _player.currentIndex,
        ));
        var item = MediaItem(
          id: _player.currentTrack!.relativePath,
          title: _player.currentTrack!.name,
          artist: _player.playlistName,
          duration: _player.duration,
          artUri: await _player.currentArtUri,
        );
        mediaItem.add(item);
      }
    });
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
    ));
    _player.playPause();
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
    ));
    _player.playPause();
  }

  @override
  Future<void> stop() async {
    _player.flushPlaying();
  }

  @override
  Future<void> seek(Duration position) async {
    _player.setPos(position.inMilliseconds);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _player.setSuqenceIndex(index);
  }
}
