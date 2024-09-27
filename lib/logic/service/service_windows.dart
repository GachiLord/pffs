import 'package:pffs/logic/state.dart';
import 'package:smtc_windows/smtc_windows.dart';

Future<void> service(PlayerState player, LibraryState prefs) async {
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
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          player.playPause();
          break;
        case PressedButton.pause:
          if (player.playing) {
            smtc.setPlaybackStatus(PlaybackStatus.Paused);
          } else {
            smtc.setPlaybackStatus(PlaybackStatus.Playing);
          }
          player.playPause();
          break;
        case PressedButton.next:
          player.playNext();
          break;
        case PressedButton.previous:
          player.playPrevious();
          break;
        case PressedButton.stop:
          // player.flushPlaying();
          smtc.setPlaybackStatus(PlaybackStatus.Stopped);
          break;
        default:
          print("event $event is not implemented");
          break;
      }
    });
  } catch (e) {
    print("Error: $e");
  }

  // handle player events
  player.completedStream.listen((v) async {
    if (player.currentTrack != null && v) {
      smtc.setPlaybackStatus(PlaybackStatus.Playing);

      smtc.updateMetadata(
        MusicMetadata(
          title: player.trackName,
          artist: player.playingObjectName,
        ),
      );
    }
  });
  player.playingStream.listen((v) async {
    if (player.currentTrack != null && v) {
      smtc.setPlaybackStatus(
          v ? PlaybackStatus.Playing : PlaybackStatus.Paused);

      smtc.updateMetadata(
        MusicMetadata(
          title: player.trackName,
          artist: player.playingObjectName,
        ),
      );
    }
  });
}
