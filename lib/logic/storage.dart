import 'dart:convert';
import 'dart:io';
import 'package:pffs/logic/core.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show Platform;

class MediaInfo {
  final Uri? artUri;
  final String relativePath;
  final String fullPath;
  final String name;

  MediaInfo(this.artUri, this.relativePath, this.fullPath, this.name);
}

Future<PlaylistConf> load(String path) async {
  var file = await File(path).readAsString();
  final json = jsonDecode(file) as Map<String, dynamic>;
  var conf = PlaylistConf.fromJson(json);

  return conf;
}

Future<List<MediaInfo>> listPlaylists(String? libraryPath) async {
  var directory = Directory(libraryPath!);
  List<MediaInfo> items = List.empty(growable: true);

  // load media items
  await for (var entity in directory.list()) {
    var fullPath = entity.path;
    var fileName = p.basename(fullPath);
    if (p.extension(fileName) == ".json") {
      var name = p.basenameWithoutExtension(fileName);
      var artUri = await getMediaArtUri(fullPath);
      items.add(MediaInfo(artUri, fileName, fullPath, name));
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
    var trackPath = p.join(libraryPath, track.relativePath);
    var artUri = await getMediaArtUri(trackPath);
    items.add(MediaInfo(artUri, track.relativePath, trackPath,
        p.basenameWithoutExtension(track.relativePath)));
  }

  return items;
}

Future<List<MediaInfo>> listTracks(String? libraryPath) async {
  List<MediaInfo> items = List.empty(growable: true);
  const musicFiles = [
    ".mp3",
    ".m4a",
    ".mp4",
    ".webm",
    ".matroska",
    ".ogg",
    ".wav",
    ".flv",
    ".adts",
    ".flac",
    ".amr"
  ];
  var directory = Directory(libraryPath!);
  // sort track files by date
  List<FileSystemEntity> entities =
      await directory.list(recursive: true).toList();
  entities.sort((a, b) => b.statSync().changed.compareTo(a.statSync().changed));

  // get mediainfo
  for (var entity in entities) {
    var fullPath = entity.path;
    var fileName = p.relative(fullPath, from: libraryPath);
    if (musicFiles.contains(p.extension(fullPath).toLowerCase())) {
      var name = p.basenameWithoutExtension(fileName);
      var artUri = await getMediaArtUri(fullPath);
      items.add(MediaInfo(artUri, fileName, fullPath, name));
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
  var artUri = await getMediaArtUri(path);
  file.writeAsString(jsonEncode(playlist.toJson()));
  return MediaInfo(artUri, relativePath, path, name);
}

Future<PlaylistConf> createPlaylistFromDir(String libraryPath, String relativeDirPath) async {
  var tracks = await listTracks(p.join(libraryPath, relativeDirPath));

  tracks.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  
  return PlaylistConf(
    tracks: tracks.map((t) => TrackConf(relativePath: p.Context(style: p.Style.posix).join(relativeDirPath, t.relativePath))).toList()
  );
}

Future<void> setTrackIndexPlaylist(
    String playlistFullPath, int oldIndex, int newIndex) async {
  var playlist = await load(playlistFullPath);
  var track = playlist.tracks.removeAt(oldIndex);
  playlist.tracks.insert(newIndex, track);
  await save(playlistFullPath, playlist);
}

Future<void> setTrackPlaylist(
    String playlistFullPath, int index, TrackConf conf) async {
  var playlist = await load(playlistFullPath);
  playlist.tracks[index] = conf;
  await save(playlistFullPath, playlist);
}

Future<void> addToPlaylist(String playlistFullPath, MediaInfo trackInfo) async {
  var playlist = await load(playlistFullPath);
  playlist.tracks.add(TrackConf(
      relativePath: Platform.isWindows ? trackInfo.relativePath.replaceAll(p.windows.separator, p.posix.separator) : trackInfo.relativePath,
      volume: VolumeConf(),
      skip: SkipConf()));
  await save(playlistFullPath, playlist);
}

Future<void> deleteFromPlaylist(String playlistFullPath, int index) async {
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
  return await File(artPath).exists()
      ? Uri.file(artPath, windows: Platform.isWindows)
      : null;
}
