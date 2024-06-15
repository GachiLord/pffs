import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as audio;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/pages/playlists.dart';
import 'package:pffs/widgets/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/library.dart';
import 'package:pffs/logic/service/service_linux.dart' as linux_service;
import 'package:pffs/logic/service/service_windows.dart' as windows_service;
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
  var player = audio.AudioPlayer(
      audioLoadConfiguration: const audio.AudioLoadConfiguration(
          androidLoadControl: audio.AndroidLoadControl(
              minBufferDuration: Duration(seconds: 20))));
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  // init state
  var libState = LibraryState(prefs);
  var playerState = PlayerState(prefs, player);
  // init background audio service
  if (Platform.isLinux) {
    linux_service.service(playerState);
  } else if (Platform.isWindows) {
    windows_service.service(playerState);
  } else {
    await JustAudioBackground.init(
      preloadArtwork: true,
      androidNotificationIcon: 'drawable/player_icon',
      androidNotificationChannelId: 'com.gachilord.pffs.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
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
        prefs: prefs,
      ),
    ),
  );
}

class App extends StatelessWidget {
  final SharedPreferences prefs;

  const App({required this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Navigation(prefs: prefs),
    );
  }
}

class Navigation extends StatefulWidget {
  final SharedPreferences prefs;

  const Navigation({required this.prefs, super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

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
            const Library(),
            Playlists(path: state.libraryPath),
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
