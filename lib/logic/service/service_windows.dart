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
      print(event);
      switch (event) {
        case PressedButton.play:
          if (player.playing) {
            player.pause();
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            player.play();
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          break;
        case PressedButton.pause:
          if (player.playing) {
            player.pause();
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            player.play();
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          break;
        case PressedButton.next:
          player.seekToNext();
          break;
        case PressedButton.previous:
          player.seekToPrevious();
          break;
        case PressedButton.stop:
          // TODO: add flushPlaying here
          // smtc.setPlaybackStatus(PlaybackStatus.Stopped);
          // smtc.disableSmtc();
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
