import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class LibraryState extends ChangeNotifier {
  final SharedPreferences _prefs;
  String? _libraryPath;

  LibraryState(SharedPreferences prefs)
      : _prefs = prefs,
        _libraryPath = prefs.getString("libraryPath");

  String? get libraryPath => _libraryPath;

  void setLibraryPath(String path) {
    _libraryPath = path;
    _prefs.setString("libraryPath", path);
    notifyListeners();
  }
}

enum PlayingObject { library, playlist, nothing }

class PlayerState extends ChangeNotifier {
  late final SharedPreferences _prefs;
  late final AudioPlayer _player;
  List<MediaInfo>? _currentSequnce;
  ConcatenatingAudioSource? _currentSource;
  late double _maxVolume;
  double _currentVolume = 1.0;

  /// should not be modified in this class, because it is a ref to ui state
  PlaylistConf? _currentPlaylist;
  PlayingObject _playingObject = PlayingObject.nothing;

  PlayerState(SharedPreferences prefs, AudioPlayer player) {
    _player = player;
    _prefs = prefs;
    _maxVolume = prefs.getDouble("volume") ?? 1.0;
    _player.setVolume(_maxVolume);
    _sequenceObserver();
    _positionObserver();
    _playingObserver();
  }

  PlayingObject get playingObject => _playingObject;
  PlaylistConf? get currentPlaylist => _currentPlaylist;
  bool get playing => _player.playing;
  double get volume => _maxVolume;
  Duration get pos => _player.position;
  Duration? get duration => _player.duration;
  String? get trackName {
    var index = _player.currentIndex;
    if (index != null) {
      if (_currentSequnce != null) {
        return _currentSequnce![index].name;
      }
    }
    return null;
  }

  @override
  void dispose() {
    flushPlaying();
    _player.dispose();
    super.dispose();
  }

  void setPos(int seconds) {
    _player.seek(Duration(seconds: seconds));
  }

  void setVolume(double volume) {
    _player.setVolume(volume * _currentVolume);
    _maxVolume = volume;
    _prefs.setDouble("volume", _maxVolume);
    notifyListeners();
  }

  void playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      if (_currentSource != null) {
        if (!Platform.isWindows) _player.stop();
        _player.play();
      }
    }
  }

  void playNext() {
    _player.seekToNext();
  }

  void playPrevious() {
    _player.seekToPrevious();
  }

  void playTracks(List<MediaInfo> tracks, int startIndex) {
    _currentSequnce = tracks;
    _currentPlaylist = null;
    _playingObject = PlayingObject.library;

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: tracks
          .mapIndexed((i, t) => AudioSource.file(
                t.fullPath,
                tag: MediaItem(
                  // Specify a unique ID for each media item:
                  id: i.toString(),
                  // Metadata to display in the notification:
                  album: "Library",
                  title: t.name,
                ),
              ))
          .toList(),
    );
    _currentSource = source;
    _player.setAudioSource(source, initialIndex: startIndex);
    _player.setLoopMode(LoopMode.all);
    _player.play();
  }

  void playPlaylist(String libraryPath, PlaylistConf playlist,
      String playlistName, int startIndex) {
    _currentSequnce =
        playlist.tracks.map((t) => t.getMediaInfo(libraryPath)).toList();
    _currentPlaylist = playlist;
    _playingObject = PlayingObject.playlist;

    // TODO: find out what's wrong in here
    //
    // collect playlist children
    // var children = List.empty(growable: true);
    // for (var i = 0; i < _currentSequnce!.length; i++) {
    //   var t = _currentSequnce![i];
    //   var tag = MediaItem(
    //     // Specify a unique ID for each media item:
    //     id: i.toString(),
    //     // Metadata to display in the notification:
    //     album: playlistName,
    //     title: t.name,
    //   );
    //   File(t.fullPath).exists().then((exist) {
    //     if (exist) {
    //       children.add(AudioSource.asset("assets/silence.mp3", tag: tag));
    //     } else {
    //       children.add(AudioSource.file(
    //         t.fullPath,
    //         tag: tag,
    //       ));
    //     }
    //   });
    // }

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: _currentSequnce!.mapIndexed((i, t) {
        var tag = MediaItem(
          // Specify a unique ID for each media item:
          id: i.toString(),
          // Metadata to display in the notification:
          album: playlistName,
          title: t.name,
        );
        // TODO: fix this sync call
        if (!File(t.fullPath).existsSync()) {
          return AudioSource.asset("assets/silence.mp3", tag: tag);
        }
        return AudioSource.file(
          t.fullPath,
          tag: tag,
        );
      }).toList(),
    );
    _currentSource = source;
    _player.setAudioSource(source, initialIndex: startIndex);
    _player.setLoopMode(LoopMode.all);
    _player.play();
  }

  void setSuqenceIndex(int index) {
    if (Platform.isAndroid) _player.stop();
    _player.seek(null, index: index);
    _player.play();
  }

  void movePlaylistTrack(int startIndex, int endIndex) {
    var path = _currentSequnce!.removeAt(startIndex);
    _currentSequnce!.insert(endIndex, path);
    _currentSource!.move(startIndex, endIndex);
  }

  void setPlaylistTrack(String libraryPath, int index, TrackConf track) {
    var info = track.getMediaInfo(libraryPath);
    _currentSequnce![index] = info;
  }

  void flushPlaying() {
    _player.stop();
    _currentSequnce = null;
    _currentSource = null;
    _playingObject = PlayingObject.nothing;
  }

  void addToPlaylist(
      String libraryPath, PlaylistConf playlist, TrackConf track) {
    var info = track.getMediaInfo(libraryPath);
    _currentSequnce!.add(info);
    _currentSource!.add(AudioSource.file(info.fullPath));
  }

  void deleteTrack(int index) {
    _currentSequnce!.removeAt(index);
    _currentSource!.removeAt(index);
  }

  /// Should be called only once
  void _sequenceObserver() async {
    Timer? timer;
    int counter = 0;
    await for (final index in _player.currentIndexStream) {
      if (_currentPlaylist != null && index != null) {
        // stop last effect
        counter = 0;
        if (timer != null) {
          timer.cancel();
        }
        // apply effects
        var track = _currentPlaylist!.tracks[index];
        //var skip = track.skip; TODO: implement skip effect
        var volume = track.volume;

        if (volume.isActive) {
          _currentVolume = volume.startVolume;
          _player.setVolume(_currentVolume * _maxVolume);
          var step = (volume.endVolume - volume.startVolume).abs() /
              (volume.transitionTimeSeconds > 0
                  ? volume.transitionTimeSeconds
                  : 1);
          timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!_player.playing) return;

            if (counter == volume.transitionTimeSeconds) t.cancel();
            counter++;
            if (volume.endVolume > volume.startVolume) {
              _currentVolume += step;
            } else {
              _currentVolume -= step;
            }
            _player.setVolume(min(_currentVolume * _maxVolume, 1.0));
          });
        } else {
          _currentVolume = 1.0;
          _player.setVolume(min(_currentVolume * _maxVolume, 1.0));
        }
      }

      notifyListeners();
    }
  }

  /// Should be called only once
  void _positionObserver() async {
    await for (final _ in _player.positionStream) {
      notifyListeners();
    }
  }

  /// Should be called only once
  void _playingObserver() async {
    await for (final _ in _player.playingStream) {
      notifyListeners();
    }
  }
}
