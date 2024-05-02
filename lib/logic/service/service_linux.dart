import 'package:just_audio/just_audio.dart';
import 'package:mpris_service/mpris_service.dart';

Future<void> service(AudioPlayer player) async {
  final instance = await MPRIS.create(
    busName: 'org.mpris.MediaPlayer2.pffs',
    identity: 'pffs',
    desktopEntry: '/usr/share/applications/pffs',
  );
  instance.setEventHandler(
    MPRISEventHandler(
      playPause: () async {
        if (player.playing) {
          player.pause();
        } else {
          player.play();
        }
        instance.playbackStatus =
            instance.playbackStatus == MPRISPlaybackStatus.playing
                ? MPRISPlaybackStatus.paused
                : MPRISPlaybackStatus.playing;
      },
      stop: () async {
        player.pause();
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
        player.seekToNext();
      },
      previous: () async {
        player.seekToPrevious();
      },
    ),
  );
}
