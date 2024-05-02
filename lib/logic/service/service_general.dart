import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AppAudioHandler extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  // mix in default seek callback implementations

  late final AudioPlayer _player; // e.g. just_audio

  AppAudioHandler(player) {
    _player = player;
  }

  // The most common callbacks:
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);
}

Future<void> service(AudioPlayer player) async {
  await AudioService.init(
    builder: () => AppAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.gachilord.pffs.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
}
