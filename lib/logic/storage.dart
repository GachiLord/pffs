import 'dart:convert';
import 'dart:io';
import 'package:pffs/logic/core.dart';
import 'package:path/path.dart' as p;

class MediaInfo {
  final String relativePath;
  final String fullPath;
  final String name;

  MediaInfo(this.relativePath, this.fullPath, this.name);
}

Future<PlaylistConf> load(String path) async {
  var file = await File(path).readAsString();
  final json = jsonDecode(file) as Map<String, dynamic>;
  var conf = PlaylistConf.fromJson(json);

  return conf;
}

Future<List<MediaInfo>> listPlaylists(String? libraryPath) async {
  List<MediaInfo> items = List.empty(growable: true);
  var directory = Directory(libraryPath!);

  await for (var entity in directory.list()) {
    var fullPath = entity.path;
    var fileName = p.basename(fullPath);
    if (p.extension(fileName) == ".json") {
      var name = p.basenameWithoutExtension(fileName);
      items.add(MediaInfo(fileName, fullPath, name));
    }
  }

  return items;
}

Future<List<MediaInfo>> listPlaylistTracks(
    String libraryPath, String playlistName) async {
  List<MediaInfo> items = List.empty(growable: true);
  var filePath = p.join(libraryPath, playlistName);
  filePath = p.setExtension(filePath, ".json");
  var tracks = await load(filePath);
  for (var track in tracks.tracks) {
    items.add(MediaInfo(track.relativePath, filePath, track.name));
  }

  return items;
}

Future<List<MediaInfo>> listTracks(String? libraryPath) async {
  List<MediaInfo> items = List.empty(growable: true);
  const musicFiles = [
    ".mp3",
    ".m4a",
    ".mp4",
    "webm",
    "matroska",
    "ogg",
    "wav",
    "flv",
    "adts",
    "flac",
    "amr"
  ];
  var directory = Directory(libraryPath!);
  await for (var entity in directory.list(recursive: true)) {
    var fullPath = entity.path;
    var fileName = p.basename(fullPath);
    if (musicFiles.contains(p.extension(fullPath).toLowerCase())) {
      var name = p.basenameWithoutExtension(fileName);
      items.add(MediaInfo(fileName, fullPath, name));
    }
  }

  return items;
}

Future<void> save(String path, PlaylistConf playlist) async {
  var file = File(path);
  file.writeAsString(jsonEncode(playlist.toJson()));
}

Future<MediaInfo> createPlaylist(
    String libraryPath, String name, PlaylistConf playlist) async {
  var relativePath = p.setExtension(name, ".json");
  var path = p.join(libraryPath, relativePath);
  var file = File(path);
  if (await file.exists() || name == "") {
    throw PathExistsException(path, const OSError("Path exists"));
  }
  file.writeAsString(jsonEncode(playlist.toJson()));
  return MediaInfo(relativePath, path, name);
}

Future<void> setTrackIndexPlaylist(
    String playlistFullPath, int oldIndex, int newIndex) async {
  // TODO: sync global state
  var playlist = await load(playlistFullPath);
  var track = playlist.tracks.removeAt(oldIndex);
  playlist.tracks.insert(newIndex, track);
  await save(playlistFullPath, playlist);
}

Future<void> setTrackPlaylist(
    String playlistFullPath, int index, TrackConf conf) async {
  // TODO: sync global state
  var playlist = await load(playlistFullPath);
  playlist.tracks[index] = conf;
  await save(playlistFullPath, playlist);
}

Future<void> addToPlaylist(String playlistFullPath, MediaInfo trackInfo) async {
  // TODO: addition of track to global state
  var playlist = await load(playlistFullPath);
  playlist.tracks.add(TrackConf(
      relativePath: trackInfo.relativePath,
      name: trackInfo.name,
      volume: VolumeConf.defaultConf(),
      skip: SkipConf.defaultConf()));
  await save(playlistFullPath, playlist);
}

Future<void> deleteFromPlaylist(String playlistFullPath, int index) async {
  // TODO: addition of track to global state
  var playlist = await load(playlistFullPath);
  playlist.tracks.removeAt(index);
  await save(playlistFullPath, playlist);
}

Future<void> deleteEntity(String fullPath) async {
  var file = File(fullPath);
  await file.delete();
}

Future<Uri?> getMediaArtUri(String mediaFullPath) async {
  var artPath = p.setExtension(mediaFullPath, ".png");
  return await File(artPath).exists() ? Uri.file(artPath) : null;
}
