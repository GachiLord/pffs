import 'package:pffs/logic/state.dart';
import 'package:smtc_windows/smtc_windows.dart';

Future<void> service(PlayerState player) async {
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
          if (player.playing) {
            player.playPause();
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            player.playPause();
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          break;
        case PressedButton.pause:
          if (player.playing) {
            player.playPause();
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            player.playPause();
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          break;
        case PressedButton.next:
          player.playNext();
          break;
        case PressedButton.previous:
          player.playPrevious();
          break;
        case PressedButton.stop:
          player.flushPlaying();
          smtc.setPlaybackStatus(PlaybackStatus.Stopped);
          smtc.disableSmtc();
          break;
        default:
          print("event $event is not implemented");
          break;
      }
    });
  } catch (e) {
    print("Error: $e");
  }
}
