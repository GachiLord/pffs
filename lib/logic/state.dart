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
  late String? _libraryPath;

  PlayerState(SharedPreferences prefs, AudioPlayer player) {
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

    var conf = _playlist!.tracks[_index];
    var start = conf.volume.startVolume;
    var end = conf.volume.endVolume;
    var time = conf.volume.transitionTimeSeconds;

    if (_volume == end) return;

    var delta = ((end - start) / (10 * time)).abs();
    _volume = min(_volume + delta, end);
    print(_volume);
    await _setLimitedVolume();
  }

  // sequence

  String _playlistName = "Unknown";
  PlayingObject _playingObject = PlayingObject.nothing;
  LoopMode _loopMode = LoopMode.all;
  List<int>? _shuffleIndexes;
  Uri? _artUri;
  MediaInfo? _track;
  int _index = 0;
  bool _shuffled = false;
  // should not be modified here, because it is a ref owned by UI
  PlaylistConf? _playlist;

  LoopMode get loopMode => _loopMode;
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
    _loopMode = p.loopMode ?? LoopMode.all;
    _index = startIndex;
    _shuffled = p.shuffled ?? false;
    if (p.tracks.isNotEmpty) {
      await _playItem(p.tracks[startIndex]);
    }
    notifyListeners();
  }

  _playItem(TrackConf item) async {
    // TODO: handle effects
    //
    // media
    var media = item.getMediaInfo(_libraryPath!);
    var artUri = await getMediaArtUri(media.fullPath) ??
        await getMediaArtUri(p.join(_libraryPath!, _playlistName));
    var tag = MediaItem(
        // Specify a unique ID for each media item:
        id: media.fullPath,
        // Metadata to display in the notification:
        album: _playlistName,
        title: media.name,
        extras: {"loadThumbnailUri": true},
        artUri: artUri);
    // effects
    var start = Duration(seconds: item.skip.start);
    var end = Duration(seconds: item.skip.end);

    _track = media;
    _artUri = artUri;
    await _player.setAudioSource(
      AudioSource.file(media.fullPath, tag: tag),
    );
    await _player.setClip(
        start: start == Duration.zero ? null : start,
        end: end == Duration.zero ? null : end);
  }

  // playback

  Duration get pos => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
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
      if (newIndex > _playlist!.tracks.length) {
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

    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    notifyListeners();
  }

  void changeShuffleMode() {
    _shuffled = !_shuffled;
    notifyListeners();
  }

  void changeLoopMode() {
    // update in player
    switch (_player.loopMode) {
      case LoopMode.off:
        {
          _player.setLoopMode(LoopMode.all);
          break;
        }
      case LoopMode.all:
        {
          _player.setLoopMode(LoopMode.one);
          break;
        }
      case LoopMode.one:
        {
          _player.setLoopMode(LoopMode.off);
          break;
        }
    }
    if (_playingObject == PlayingObject.playlist) {
      // update playlist model
      _playlist!.loopMode = _player.loopMode;
      // update playlist file
      var path = p.setExtension(p.join(_libraryPath!, _playlistName), ".json");
      save(path, _playlist!);
    }
    notifyListeners();
  }

  void setPos(int pos) {
    _player.seek(Duration(milliseconds: pos));
  }

  // sound

  double _volume = 1.0;
  late double _maxVolume;

  double get volume => _maxVolume;

  void setVolume(double v) {
    _player.setVolume(v * _volume);
    _maxVolume = v;
    _prefs.setDouble("volume", _maxVolume);
    notifyListeners();
  }

  _setLimitedVolume() async {
    await _player.setVolume(_volume * _maxVolume);
  }

  _setStartVolume(TrackConf? item) async {
    if (item != null && item.volume.isActive) {
      _volume = item.volume.startVolume;
      await _setLimitedVolume();
    }
  }

  // observers

  void _positionObserver() async {
    await for (final _ in _player.positionStream) {
      notifyListeners();
    }
  }

  void _processingStateObserver() async {
    await for (final state in _player.processingStateStream) {
      if (state == ProcessingState.loading) {
        print("load");
        // set volume to start value
        var item = _fetchCurrent();
        if (item != null) {
          _setStartVolume(item);
        }
      }
      if (state == ProcessingState.completed) {
        print("compl");
        var item = _fetchNext();
        if (item != null) {
          _setStartVolume(item);
          _playItem(item);
        }
      }
    }
  }
}
