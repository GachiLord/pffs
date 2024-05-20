import 'package:smtc_windows/smtc_windows.dart';
import 'package:just_audio/just_audio.dart';

Future<void> service(AudioPlayer player) async {
  var smtc = SMTCWindows(
    config: const SMTCConfig(
      fastForwardEnabled: true,
      nextEnabled: true,
      pauseEnabled: true,
      playEnabled: true,
      rewindEnabled: false,
      prevEnabled: true,
      stopEnabled: true,
    ),
  );
  // Listen to button events and update playback status accordingly
  try {
    smtc.buttonPressStream.listen((event) {
      switch (event) {
        case PressedButton.play:
          smtc.setPlaybackStatus(PlaybackStatus.Playing);
          if (player.playing) {
            player.pause();
          } else {
            player.play();
          }
          break;
        case PressedButton.pause:
          smtc.setPlaybackStatus(PlaybackStatus.Paused);
          player.pause();
          break;
        case PressedButton.next:
          player.seekToNext();
          break;
        case PressedButton.previous:
          player.seekToPrevious();
          break;
        case PressedButton.stop:
          smtc.setPlaybackStatus(PlaybackStatus.Stopped);
          smtc.disableSmtc();
          player.pause();
          break;
        default:
          break;
      }
    });
  } catch (e) {
    print("Error: $e");
  }
}
