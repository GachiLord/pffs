import 'package:flutter/material.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/logic/storage.dart';
import 'package:pffs/widgets/mini_player.dart';
import '../elements/track.dart';
import '../util/informing.dart';

class Playlist extends StatefulWidget {
  final PlayerState playerState;
  final String libraryPath;
  final MediaInfo info;

  @override
  State<Playlist> createState() => _PlatlistState();

  const Playlist(
      {super.key,
      required this.info,
      required this.libraryPath,
      required this.playerState});
}

class _PlatlistState extends State<Playlist> {
  late final Future<PlaylistConf> playlist = load(widget.info.fullPath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const MiniPlayerAppBar(),
        body: FutureBuilder(
            future: playlist,
            builder: (BuildContext ctx, AsyncSnapshot snapshot) {
              Widget output = const Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
              );
              if (snapshot.hasData) {
                output = ReorderableListView.builder(
                  prototypeItem: snapshot.data.tracks.isNotEmpty
                      ? Track(
                          key: const Key('0'),
                          libraryPath: widget.libraryPath,
                          trackInfo: snapshot.data.tracks.first
                              .getMediaInfo(widget.libraryPath),
                          playlistRelativePath: widget.info.relativePath,
                          playlists: const [],
                          index: 0,
                          playlistInfo: snapshot.data,
                          elementOf: PlayingObject.playlist,
                          onAction: (TrackAction a) {
                            if (a == TrackAction.delete) {
                              deleteFromPlaylist(widget.info.fullPath, 0)
                                  .catchError((_) {
                                if (context.mounted) {
                                  showToast(
                                      context, "Failed to delete the track");
                                }
                              });
                              setState(() {
                                playlist.then((value) => {
                                      value.tracks.removeAt(0),
                                    });
                              });
                              widget.playerState.flushPlaying();
                            }
                          },
                        )
                      : null,
                  itemCount: snapshot.data.tracks.length,
                  itemBuilder: (context, index) {
                    return Track(
                      key: Key('$index'),
                      libraryPath: widget.libraryPath,
                      trackInfo: snapshot.data.tracks[index]
                          .getMediaInfo(widget.libraryPath),
                      playlistRelativePath: widget.info.relativePath,
                      playlists: const [],
                      index: index,
                      playlistInfo: snapshot.data,
                      elementOf: PlayingObject.playlist,
                      onAction: (TrackAction a) {
                        if (a == TrackAction.delete) {
                          deleteFromPlaylist(widget.info.fullPath, index)
                              .catchError((_) {
                            if (context.mounted) {
                              showToast(context, "Failed to delete the track");
                            }
                          });
                          setState(() {
                            playlist.then((value) => {
                                  value.tracks.removeAt(index),
                                });
                          });
                          widget.playerState.flushPlaying();
                        }
                      },
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    playlist.then((value) {
                      setTrackIndexPlaylist(
                          widget.info.fullPath, oldIndex, newIndex);
                      setState(() {
                        final item = value.tracks.removeAt(oldIndex);
                        value.tracks.insert(newIndex, item);
                        widget.playerState.flushPlaying();
                      });
                    });
                  },
                );
              } else if (snapshot.hasError) {
                output = const Center(
                  child: Text(
                    "Playlist file is corrupted",
                    style: TextStyle(fontSize: 28),
                  ),
                );
              }
              return output;
            }));
  }
}
