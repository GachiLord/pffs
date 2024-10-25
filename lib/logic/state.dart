import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

class LibraryState extends ChangeNotifier {
  final SharedPreferences _prefs;
  String? _libraryPath;

  LibraryState(SharedPreferences prefs)
      : _prefs = prefs,
        _libraryPath = prefs.getString("libraryPath");

  String? get libraryPath => _libraryPath;

  Future<void> setLibraryPath(String path) async {
    _libraryPath = path;
    await _prefs.setString("libraryPath", path);
    notifyListeners();
  }
}

enum PlayingObject { library, playlist, nothing }

class PlayerState extends ChangeNotifier {
  late final SharedPreferences _prefs;
  late final Player _player;
  late String? _libraryPath;

  PlayerState(SharedPreferences prefs, Player player) {
    _player = player;
    _prefs = prefs;
    _libraryPath = _prefs.getString("libraryPath");
    _maxVolume = prefs.getDouble("volume") ?? 1.0;
    _player.setVolume(_maxVolume);
    // launch observers
    _processingStateObserver();
    _positionObserver();
    _playingObserver();
  }

  // effects

  void _soundEffect() async {
    if (_playlist == null) return;
    if (_index! >= _playlist!.tracks.length) return;

    var conf = _playlist!.tracks[_index!];

    if (!conf.volume.isActive) return;

    var start = conf.volume.startVolume;
    var end = conf.volume.endVolume;
    var time = conf.volume.transitionTimeSeconds;

    if (_volume == end) return;

    var delta = ((end - start) / (max(1, 10 * time))).abs();
    _volume = min(_volume + delta, end);
    await _setLimitedVolume();
  }

  void _skipEffect(int posSeconds) async {
    if (_playlist == null) return;
    if (_index! >= _playlist!.tracks.length) return;

    var conf = _playlist!.tracks[_index!];

    if (conf.skip.isActive &&
        conf.skip.end != 0 &&
        posSeconds >= conf.skip.end) {
      var item = _fetchNext();
      if (item != null) {
        _playItem(item);
      }
    }
  }

  // sequence

  String _playlistName = "Unknown";
  PlayingObject _playingObject = PlayingObject.nothing;
  PlaylistMode _loopMode = PlaylistMode.loop;
  List<int>? _shuffleIndexes;
  Uri? _artUri;
  MediaInfo? _track;
  int? _index = 0;
  bool _shuffled = false;
  final Random _random = Random();
  // should not be modified here, because it is a ref owned by UI
  PlaylistConf? _playlist;

  Stream<bool> get completedStream => _player.stream.completed;
  String? get playlistName => _playlistName;
  PlaylistMode get loopMode => _loopMode;
  PlaylistConf? get currentPlaylist => _playlist;
  MediaInfo? get currentTrack => _track;
  Future<Uri?> get currentArtUri async {
    if (_index != null && _playlist != null) {
      final trackPath =
          p.join(_libraryPath!, _playlist!.tracks[_index!].relativePath);
      final playlistPath =
          p.join(_prefs.getString("libraryPath") ?? "", _playlistName);

      return await getMediaArtUri(trackPath) ??
          await getMediaArtUri(playlistPath);
    }

    return null;
  }

  Uri? get currentArtUriSync => _artUri;
  String? get trackName => _track?.name;
  int? get currentIndex => _shuffled ? _shuffleIndexes![_index!] : _index;
  PlayingObject get playingObject => _playingObject;
  String? get playingObjectName => _playlistName;

  void updateLibraryPath() {
    _libraryPath = _prefs.getString("libraryPath");
  }

  void _createShuffleIndexes(int len) {
    _shuffleIndexes = List.generate(len, (i) => i);
    _shuffleIndexes!.shuffle(_random);
  }

  Future<void> setSequence(
      PlaylistConf p, PlayingObject type, String name, int startIndex) async {
    _playingObject = type;
    _playlist = p;
    _playlistName = name;
    _loopMode = p.loopMode ?? PlaylistMode.loop;
    _index = startIndex;
    _shuffled = p.shuffled ?? false;
    // play
    if (p.tracks.isNotEmpty) {
      if (_shuffled) {
        // handle shuffled mode
        _createShuffleIndexes(p.tracks.length);
        _index = _shuffleIndexes!.indexOf(_index!);
        await _playItem(p.tracks[startIndex]);
      } else {
        // handle normal mode
        await _playItem(p.tracks[_index!]);
      }
    }
    notifyListeners();
  }

  Future<void> _playItem(TrackConf item) async {
    // handle sound effect
    await _setStartVolume(item);
    // handle speed effect
    await _setSpeed(item);
    // media
    var media = item.getMediaInfo(_libraryPath!);
    var artUri = await getMediaArtUri(media.fullPath) ??
        await getMediaArtUri(p.join(_libraryPath!, _playlistName));
    // play audio
    _track = media;
    _artUri = artUri;
    await _player.open(Media(media.fullPath), play: true);
    // apply skipEffect
    if (item.skip.isActive) {
      var start = Duration(seconds: item.skip.start);
      await _player.seek(start);
    }
  }

  void flushPlaying() {
    _player.stop();
    _playlist = null;
    _index = null;
    _playingObject = PlayingObject.nothing;
    _artUri = null;
    _playlistName = "Unknown";
    _shuffleIndexes = null;
    _track = null;
    _shuffled = false;
    notifyListeners();
  }

  // playback

  double get speed => _player.state.rate;
  Duration get pos => _player.state.position;
  Duration? get duration =>
      _player.state.duration == Duration.zero ? null : _player.state.duration;
  bool get playing => _player.state.playing;
  bool get shuffleOrder => _shuffled;
  Stream<bool> get playingStream => _player.stream.playing;
  Stream<Duration> get durationStream => _player.stream.duration;

  final StreamController<Duration> _seekStreamController = StreamController();
  Stream<Duration> get seekStream => _seekStreamController.stream;

  Future<void> _setSpeed(TrackConf item) async {
    await _player.setRate(item.speed.isActive ? item.speed.speed : 1.0);
  }

  void setSuqenceIndex(int index) async {
    // handle shuffle mode
    if (_shuffled) {
      _index = _shuffleIndexes!.indexOf(index);
    } else {
      _index = index;
    }
    var item = _playlist!.tracks[index];
    // apply sound effect
    await _setStartVolume(item);
    // play
    _playItem(item);
    notifyListeners();
  }

  Future<void> playPrevious() async {
    var item = _fetchPrevious();
    await _setStartVolume(item);
    if (item != null) {
      _playItem(item);
    }
    notifyListeners();
  }

  TrackConf? _fetchPrevious() {
    if (_playlist == null) return null;

    var newIndex = _index! - 1;
    if (newIndex < 0) {
      newIndex = _playlist!.tracks.length - newIndex.abs();
      if (_shuffled) _createShuffleIndexes(_playlist!.tracks.length);
    }
    _index = newIndex;

    if (_shuffled) {
      return _playlist!.tracks[_shuffleIndexes![newIndex]];
    } else {
      return _playlist!.tracks[newIndex];
    }
  }

  TrackConf? _fetchCurrent() {
    if (_playlist == null) return null;

    if (_shuffled) {
      return _playlist!.tracks[_shuffleIndexes![_index!]];
    } else {
      return _playlist!.tracks[_index!];
    }
  }

  TrackConf? _fetchNext() {
    if (_playlist == null) return null;

    var newIndex = _index! + 1;
    if (newIndex >= _playlist!.tracks.length) {
      newIndex = 0;
      if (_shuffled) _createShuffleIndexes(_playlist!.tracks.length);
    }
    _index = newIndex;

    if (_shuffled) {
      return _playlist!.tracks[_shuffleIndexes![_index!]];
    } else {
      return _playlist!.tracks[_index!];
    }
  }

  Future<void> playNext() async {
    var item = _fetchNext();
    await _setStartVolume(item);

    if (item != null) {
      _playItem(item);
    }
    notifyListeners();
  }

  void playPause() async {
    // apply sound effect
    var item = _fetchCurrent();
    await _setStartVolume(item);

    _player.playOrPause();
    notifyListeners();
  }

  void changeShuffleMode() {
    _shuffled = !_shuffled;
    if (_shuffled) {
      _createShuffleIndexes(_playlist?.tracks.length ?? 0);
      _index = _shuffleIndexes!.indexOf(_index!);
    } else {
      _index = _shuffleIndexes![_index!];
    }
    notifyListeners();
  }

  void changeLoopMode() {
    if (_player.state.playing == false) {
      _player.stop();
    }
    // update in player
    switch (_loopMode) {
      case PlaylistMode.none:
        {
          _loopMode = PlaylistMode.loop;
          break;
        }
      case PlaylistMode.loop:
        {
          _loopMode = PlaylistMode.single;
          break;
        }
      case PlaylistMode.single:
        {
          _loopMode = PlaylistMode.none;
          break;
        }
    }
    if (_playingObject == PlayingObject.playlist) {
      // update playlist model
      _playlist!.loopMode = _loopMode;
      // update playlist file
      var path = p.setExtension(p.join(_libraryPath!, _playlistName), ".json");
      save(path, _playlist!);
    }
  }

  void setPos(int pos) {
    _setStartVolume(_fetchCurrent());
    _seekStreamController.add(Duration(milliseconds: pos));
    _player.seek(Duration(milliseconds: pos));
  }

  // sound

  double _volume = 1.0;
  late double _maxVolume;

  double get volume => _maxVolume;

  void setVolume(double v) {
    _player.setVolume(v * _volume * 100);
    _maxVolume = v;
    _prefs.setDouble("volume", _maxVolume);
    notifyListeners();
  }

  Future<void> _setLimitedVolume() async {
    await _player.setVolume(_volume * _maxVolume * 100);
  }

  _setStartVolume(TrackConf? item) async {
    if (item != null && item.volume.isActive) {
      _volume = item.volume.startVolume;
    } else {
      _volume = 1.0;
    }
    await _setLimitedVolume();
  }

  // observers

  void _playingObserver() async {
    _player.stream.playing.listen((v) {
      if (!v) return;

      var item = _fetchCurrent();
      if (item == null) return;

      _setSpeed(item);
    });
  }

  void _positionObserver() async {
    _player.stream.position.listen((pos) {
      _soundEffect();
      _skipEffect(pos.inSeconds);
      notifyListeners();
    });
  }

  void _processingStateObserver() async {
    _player.stream.completed.listen((e) {
      if (e) {
        TrackConf? item;
        // handle loop mode
        if (_loopMode == PlaylistMode.single) {
          item = _fetchCurrent();
        } else if (_loopMode == PlaylistMode.none &&
            _index == _playlist!.tracks.length - 1) {
          item = null;
        } else {
          item = _fetchNext();
        }

        if (item != null) {
          _playItem(item);
        }
      }
    });
  }
}
