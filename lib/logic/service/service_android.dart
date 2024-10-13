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
          controls: [
            MediaControl.skipToPrevious,
            v ? MediaControl.play : MediaControl.pause,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.ready,
          playing: true,
          updatePosition: Duration.zero,
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
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: AudioProcessingState.ready,
          updatePosition: _player.pos,
          playing: v,
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
    _player.durationStream.listen((v) async {
      if (mediaItem.valueOrNull != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: v));
      }
    });
    _player.seekStream.listen((v) async {
      if (playbackState.valueOrNull != null) {
        playbackState.add(playbackState.value.copyWith(updatePosition: v));
      }
    });
  }

  @override
  Future<void> play() async {
    _player.playPause();
  }

  @override
  Future<void> pause() async {
    _player.playPause();
  }

  @override
  Future<void> stop() async {
    _player.playPause();
  }

  @override
  Future<void> seek(Duration position) async {
    _player.setPos(position.inMilliseconds);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _player.setSuqenceIndex(index);
  }

  @override
  Future<void> skipToNext() {
    return _player.playNext();
  }

  @override
  Future<void> skipToPrevious() {
    return _player.playPrevious();
  }
}
