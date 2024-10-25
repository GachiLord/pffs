import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:pffs/logic/state.dart';

class AudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final PlayerState _player;

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
          speed: _player.speed,
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
          speed: _player.speed,
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

Future<void> handleSession(AudioSession session, PlayerState player) async {
  var lastVolume = player.volume;
  var lastPlaying = player.playing;

  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          lastVolume = player.volume;
          player.setVolume(0.2);
          // Another app started playing audio and we should duck.
          break;
        case AudioInterruptionType.pause:
          lastPlaying = player.playing;
          player.pause();
          break;
        case AudioInterruptionType.unknown:
          lastPlaying = player.playing;
          player.pause();
          // Another app started playing audio and we should pause.
          break;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          player.setVolume(lastVolume);
          // The interruption ended and we should unduck.
          break;
        case AudioInterruptionType.pause:
          if (lastPlaying) player.play();
          break;
        // The interruption ended and we should resume.
        case AudioInterruptionType.unknown:
          if (lastPlaying) player.play();
          // The interruption ended but we should not resume.
          break;
      }
    }
  });
  session.becomingNoisyEventStream.listen((_) {
    // The user unplugged the headphones, so we should pause or lower the volume.
    player.pause();
  });
  session.devicesChangedEventStream.listen((_) {
    player.setStartVolume();
  });

  player.playingStream.listen((v) async {
    if (v) {
      if (await session.setActive(true) == false) {
        // The request was denied and the app should not play audio
        // e.g. a phonecall is in progress.
        player.pause();
      }
    }
  });
}
