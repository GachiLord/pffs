import 'package:mpris_service/mpris_service.dart';
import 'package:pffs/logic/state.dart';

Future<void> service(PlayerState player, LibraryState prefs) async {
  final instance = await MPRIS.create(
    busName: 'org.mpris.MediaPlayer2.pffs',
    identity: 'pffs',
    desktopEntry: '/usr/share/applications/pffs',
  );
  // handle mpris events
  instance.setEventHandler(
    MPRISEventHandler(
      playPause: () async {
        player.playPause();
        instance.playbackStatus =
            instance.playbackStatus == MPRISPlaybackStatus.playing
                ? MPRISPlaybackStatus.paused
                : MPRISPlaybackStatus.playing;
      },
      stop: () async {
        player.flushPlaying();
        instance.playbackStatus = MPRISPlaybackStatus.stopped;
      },
      play: () async {
        player.play();
        instance.playbackStatus = MPRISPlaybackStatus.playing;
      },
      pause: () async {
        player.pause();
        instance.playbackStatus = MPRISPlaybackStatus.paused;
      },
      next: () async {
        player.playNext();
      },
      previous: () async {
        player.playPrevious();
      },
    ),
  );
  // handle player events
  player.completedStream.listen((v) async {
    if (player.currentTrack != null && v) {
      instance.playbackStatus = MPRISPlaybackStatus.playing;

      final trackPath = player.currentTrack!.fullPath;

      instance.metadata = MPRISMetadata(
        Uri.parse(trackPath),
        artUrl: await player.currentArtUri,
        artist: [player.playingObjectName ?? "Library"],
        title: player.trackName,
      );
    }
  });
  player.playingStream.listen((v) async {
    if (player.currentTrack != null && v) {
      instance.playbackStatus =
          v ? MPRISPlaybackStatus.playing : MPRISPlaybackStatus.paused;

      final trackPath = player.currentTrack!.fullPath;

      instance.metadata = MPRISMetadata(
        Uri.parse(trackPath),
        artUrl: await player.currentArtUri,
        artist: [player.playingObjectName ?? "Library"],
        title: player.trackName,
      );
    }
  });
}
