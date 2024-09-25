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
    print("stop");
  }

  @override
  Future<void> seek(Duration position) async {
    _player.setPos(position.inMilliseconds);
  }

  // Future<void> skipToQueueItem(int i) => _player.seek(Duration.zero, index: i);
}
