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

  void setLibraryPath(String path) {
    _libraryPath = path;
    _prefs.setString("libraryPath", path);
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
  }

  // effects

  void _soundEffect() async {
    if (_playlist == null) return;
    if (_index == _playlist!.tracks.length) return;

    var conf = _playlist!.tracks[_index];
    var start = conf.volume.startVolume;
    var end = conf.volume.endVolume;
    var time = conf.volume.transitionTimeSeconds;

    if (_volume == end) return;

    var delta = ((end - start) / (10 * time)).abs();
    _volume = min(_volume + delta, end);
    await _setLimitedVolume();
  }

  void _skipEffect(int posSeconds) async {
    if (_playlist == null) return;
    if (_index == _playlist!.tracks.length) return;

    var conf = _playlist!.tracks[_index];

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
  int _index = 0;
  bool _shuffled = false;
  // should not be modified here, because it is a ref owned by UI
  PlaylistConf? _playlist;

  PlaylistMode get loopMode => _loopMode;
  PlaylistConf? get currentPlaylist => _playlist;
  MediaInfo? get currentTrack => _track;
  Uri? get currentArtUriSync => _artUri;
  String? get trackName => _track?.name;
  int? get currentIndex => _index;
  PlayingObject get playingObject => _playingObject;
  String? get playingObjectName => _playlistName;

  setSequence(
      PlaylistConf p, PlayingObject type, String name, int startIndex) async {
    _playingObject = type;
    _playlist = p;
    _playlistName = name;
    _loopMode = p.loopMode ?? PlaylistMode.loop;
    _index = startIndex;
    _shuffled = p.shuffled ?? false;
    if (p.tracks.isNotEmpty) {
      await _playItem(p.tracks[startIndex]);
    }
    notifyListeners();
  }

  _playItem(TrackConf item) async {
    // handle effects
    await _setStartVolume(item);
    // media
    var media = item.getMediaInfo(_libraryPath!);
    var artUri = await getMediaArtUri(media.fullPath) ??
        await getMediaArtUri(p.join(_libraryPath!, _playlistName));
    // play audio
    _track = media;
    _artUri = artUri;
    _player.open(Media(media.fullPath), play: true);
    // apply skipEffect
    if (item.skip.isActive) {
      var start = Duration(seconds: item.skip.start);
      _player.seek(start);
    }
  }

  // playback

  Duration get pos => _player.state.position;
  Duration? get duration => _player.state.duration;
  bool get playing => _player.state.playing;
  bool get shuffleOrder => _shuffled;

  void setSuqenceIndex(int index) async {
    _index = index;
    var item = _playlist!.tracks[index];
    // apply sound effect
    await _setStartVolume(item);
    // play
    _playItem(item);
    notifyListeners();
  }

  void playPrevious() async {
    var item = _fetchPrevious();
    await _setStartVolume(item);
    if (item != null) {
      _playItem(item);
    }
    notifyListeners();
  }

  TrackConf? _fetchPrevious() {
    if (_playlist == null) return null;

    if (_shuffled) {
      // TODO: handle shuffled mode
    } else {
      var newIndex = _index - 1;
      if (newIndex < 0) {
        newIndex = _playlist!.tracks.length - newIndex.abs();
      }
      _index = newIndex;
      return _playlist!.tracks[newIndex];
    }

    return null;
  }

  TrackConf? _fetchCurrent() {
    if (_playlist == null) return null;

    if (_shuffled) {
      // TODO: handle shuffled mode
    } else {
      return _playlist!.tracks[_index];
    }
    return null;
  }

  TrackConf? _fetchNext() {
    if (_playlist == null) return null;

    if (_shuffled) {
      // TODO: handle shuffled mode
    } else {
      var newIndex = _index + 1;
      if (newIndex == _playlist!.tracks.length) {
        newIndex = 0;
      }
      _index = newIndex;
      return _playlist!.tracks[newIndex];
    }
    return null;
  }

  void playNext() async {
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

  _setLimitedVolume() async {
    await _player.setVolume(_volume * _maxVolume * 100);
  }

  _setStartVolume(TrackConf? item) async {
    if (item != null && item.volume.isActive) {
      _volume = item.volume.startVolume;
      await _setLimitedVolume();
    }
  }

  // observers

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
