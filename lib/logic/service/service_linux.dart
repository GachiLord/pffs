import 'package:mpris_service/mpris_service.dart';
import 'package:pffs/logic/state.dart';

Future<void> service(PlayerState player, LibraryState prefs) async {
  final instance = await MPRIS.create(
    busName: 'org.mpris.MediaPlayer2.pffs',
    identity: 'pffs',
    desktopEntry: '/usr/share/applications/pffs',
  );
  instance.canQuit = true;
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
        player.pause();
        instance.canRaise = false;
        instance.canPlay = false;
        instance.canControl = false;
        instance.canGoNext = false;
        instance.canGoPrevious = false;
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
      instance.canRaise = true;
      instance.canPlay = true;
      instance.canControl = true;
      instance.canGoNext = true;
      instance.canGoPrevious = true;

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
      instance.canRaise = true;
      instance.canPlay = true;
      instance.canControl = true;
      instance.canGoNext = true;
      instance.canGoPrevious = true;

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
