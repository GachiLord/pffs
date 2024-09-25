import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/pages/playlists.dart';
import 'package:pffs/widgets/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/library.dart';
import 'package:media_kit/media_kit.dart' as audio;
import 'package:pffs/logic/service/service_linux.dart' as linux_service;
import 'package:pffs/logic/service/service_windows.dart' as windows_service;
import 'package:pffs/logic/service/service_android.dart' as android_service;
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init key-value store
  final prefs = await SharedPreferences.getInstance();
  // init player if desktop app
  audio.MediaKit.ensureInitialized();
  var player = audio.Player();
  // init state
  var libState = LibraryState(prefs);
  var playerState = PlayerState(prefs, player);
  // init background audio service
  if (Platform.isLinux) {
    linux_service.service(playerState, libState);
  } else if (Platform.isWindows) {
    windows_service.service(playerState, libState);
  } else {
    var _ = await AudioService.init(
      builder: () => android_service.AudioHandler(playerState),
      config: const AudioServiceConfig(
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
