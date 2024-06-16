import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

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
    _processingObserver();
  }
  // state for getters
  Duration? _latestDuration = Duration.zero;
  Duration _latestPos = Duration.zero;

  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  PlayingObject get playingObject => _playingObject;
  PlaylistConf? get currentPlaylist => _currentPlaylist;
  bool get playing => _player.playing;
  double get volume => _maxVolume;
  Duration get pos {
    if (_player.position != Duration.zero) {
      _latestPos = _player.position;
      return _player.position;
    } else {
      return _latestPos;
    }
  }

  Duration? get duration {
    if (_player.duration == Duration.zero || _player.duration == null) {
      return _latestDuration;
    } else {
      _latestDuration = _player.duration;
      return _player.duration;
    }
  }

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

  void setPos(int ms) {
    _player.seek(Duration(milliseconds: ms));
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

  void playTracks(List<MediaInfo> tracks, int startIndex) async {
    _currentSequnce = tracks;
    _currentPlaylist = null;
    _playingObject = PlayingObject.library;

    List<AudioSource> children = List.empty(growable: true);
    for (var i = 0; i < tracks.length; i++) {
      var t = tracks[i];
      children.add(AudioSource.file(t.fullPath,
          tag: MediaItem(
              // Specify a unique ID for each media item:
              id: i.toString(),
              // Metadata to display in the notification:
              album: "Library",
              title: t.name,
              extras: {"loadThumbnailUri": true},
              artUri: await getMediaArtUri(t.fullPath))));
    }

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: children,
    );
    _currentSource = source;
    _player.setAudioSource(source, initialIndex: startIndex);
    _player.setLoopMode(LoopMode.all);
    _player.play();
  }

  void playPlaylist(String libraryPath, PlaylistConf playlist,
      String playlistName, int startIndex) async {
    _currentSequnce =
        playlist.tracks.map((t) => t.getMediaInfo(libraryPath)).toList();
    _currentPlaylist = playlist;
    _playingObject = PlayingObject.playlist;

    List<AudioSource> children = List.empty(growable: true);
    for (var i = 0; i < _currentSequnce!.length; i++) {
      var t = _currentSequnce![i];
      var tag = MediaItem(
          // Specify a unique ID for each media item:
          id: i.toString(),
          // Metadata to display in the notification:
          album: playlistName,
          title: t.name,
          extras: {"loadThumbnailUri": true},
          artUri: await getMediaArtUri(t.fullPath) ??
              await getMediaArtUri(p.join(libraryPath, playlistName)));
      if (await File(t.fullPath).exists() == false) {
        children.add(AudioSource.asset("assets/silence.mp3", tag: tag));
      } else {
        children.add(AudioSource.file(
          t.fullPath,
          tag: tag,
        ));
      }
    }

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: children,
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

  Timer? _soundTimer;
  int _soundCounter = 0;

  void _soundEffect() {
    var index = _player.currentIndex;
    if (_currentPlaylist != null && index != null) {
      // stop last effect
      _soundCounter = 0;
      if (_soundTimer != null) {
        _soundTimer!.cancel();
      }
      // apply effects
      var track = _currentPlaylist!.tracks[index];
      var volume = track.volume;

      if (volume.isActive) {
        _currentVolume = volume.startVolume;
        _player.setVolume(_currentVolume * _maxVolume);
        var step = (volume.endVolume - volume.startVolume).abs() /
            (volume.transitionTimeSeconds > 0
                ? volume.transitionTimeSeconds
                : 1);
        _soundTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!_player.playing) return;

          if (_soundCounter == volume.transitionTimeSeconds) t.cancel();
          _soundCounter++;
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
  }

  /// Should be called only once
  void _sequenceObserver() async {
    await for (final _ in _player.currentIndexStream) {
      // apply effects
      _soundEffect();
      // update ui
      notifyListeners();
    }
  }

  /// Should be called only once
  void _processingObserver() async {
    // await for (final state in _player.processingStateStream) {
    //   if (state == ProcessingState.ready) {
    //     // apply effects
    //     _soundEffect();
    //   }
    // }
  }

  /// Should be called only once
  void _positionObserver() async {
    await for (final pos in _player.positionStream) {
      // if next track has volume conf
      // set _currentVolume to its startVolume
      var d = _player.duration ?? const Duration(seconds: 400);
      if (pos >= (d - const Duration(seconds: 1))) {
        var nextVolume = _currentPlaylist!.tracks[_player.nextIndex!].volume;
        if (_currentPlaylist != null && nextVolume.isActive) {
          _currentVolume = nextVolume.startVolume;
          _player.setVolume(min(_currentVolume * _maxVolume, 1.0));
        }
      }
      notifyListeners();
    }
  }

  /// Should be called only once
  void _playingObserver() async {
    await for (final _ in _player.playingStream) {
      // apply effects
      _soundEffect();
      notifyListeners();
    }
  }
}
