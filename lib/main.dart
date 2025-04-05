import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/pages/playlists.dart';
import 'package:pffs/widgets/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/library.dart';
import 'logic/storage.dart';
import 'logic/core.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart' as audio;
import 'package:pffs/logic/service/service_linux.dart' as linux_service;
import 'package:pffs/logic/service/service_windows.dart' as windows_service;
import 'package:pffs/logic/service/service_android.dart' as android_service;
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init key-value store
  final prefs = await SharedPreferences.getInstance();
  // init player if desktop app
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: true);
    JustAudioMediaKit.title = 'pffs';
  }
  var player = audio.AudioPlayer();
  // init state
  var libState = LibraryState(prefs);
  var playerState = await PlayerState(prefs, player);
  // try to load last playlist and track
  final int? objectType = prefs.getInt("objectType");
  final int? trackIndex = prefs.getInt("trackIndex");
  final String? playlistPath = prefs.getString("playlistPath");
  final String? libraryPath = prefs.getString("libraryPath");

  try {
    if (objectType == PlayingObject.library.index && libraryPath != null && trackIndex != null) {
      final tracks = await listTracks(libraryPath);

      if (trackIndex < tracks.length) {
        // create playlist from library
        var conf = PlaylistConf(
            tracks: tracks
                .map((v) => TrackConf(relativePath: v.relativePath))
                .toList(growable: false));
        playerState.setSequence(conf, PlayingObject.library, "library", trackIndex, shouldStart: false);
      }      
      else {
        prefs.remove("objectType");
        prefs.remove("trackIndex");
        prefs.remove("playlistPath");
      }
    }

    if (objectType == PlayingObject.playlist.index && playlistPath != null && trackIndex != null) {
      final conf = await load(playlistPath);
      playerState.setSequence(conf, PlayingObject.playlist, p.basenameWithoutExtension(playlistPath), trackIndex, shouldStart: false);
    }
  }
  catch(e) {
    print(e);
    prefs.remove("objectType");
    prefs.remove("trackIndex");
    prefs.remove("playlistPath");
  }
  // init background audio service
  if (Platform.isLinux) {
    linux_service.service(playerState, libState);
  } else if (Platform.isWindows) {
    windows_service.service(playerState, libState);
  } else {
    // handle audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // handle audio service
    var _ = await AudioService.init(
      builder: () => android_service.AudioHandler(playerState),
      config: const AudioServiceConfig(
        preloadArtwork: true,
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/player_icon',
        androidNotificationChannelId: 'com.gachilord.pffs.channel.audio',
        androidNotificationChannelName: 'Music playback',
      ),
    );
  }
  // run app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => libState),
        ChangeNotifierProvider(create: (context) => playerState)
      ],
      child: App(
        playerState: playerState,
        prefs: prefs,
      ),
    ),
  );
}

class App extends StatelessWidget {
  final SharedPreferences prefs;
  final PlayerState playerState;

  const App({required this.prefs, required this.playerState, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Navigation(
        prefs: prefs,
        playerState: playerState,
      ),
    );
  }
}

class Navigation extends StatefulWidget {
  final SharedPreferences prefs;
  final PlayerState playerState;

  const Navigation({required this.prefs, required this.playerState, super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const MiniPlayerAppBar(),
        body: Consumer<LibraryState>(builder: (context, state, child) {
          return <Widget>[
            Library(playerState: widget.playerState),
            Playlists(
              path: state.libraryPath,
              playerState: widget.playerState,
            ),
          ][currentPageIndex];
        }),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.amber,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.library_music),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.featured_play_list),
              label: 'Playlists',
            ),
          ],
        ));
  }
}
