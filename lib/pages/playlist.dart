import 'package:flutter/material.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/logic/storage.dart';
import 'package:pffs/widgets/mini_player.dart';
import 'package:provider/provider.dart';
import '../elements/track.dart';
import '../util/informing.dart';

class Playlist extends StatefulWidget {
  final String libraryPath;
  final MediaInfo info;

  @override
  State<Playlist> createState() => _PlatlistState();

  const Playlist({super.key, required this.info, required this.libraryPath});
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
                          index: 0,
                          playlistInfo: snapshot.data,
                          elementOf: PlayingObject.playlist,
                          onAction: (TrackAction a) {
                            if (a == TrackAction.delete) {
                              deleteFromPlaylist(widget.info.fullPath, 0)
                                  .catchError((_) => showToast(
                                      context, "Failed to delete the track"));
                              setState(() {
                                playlist.then((value) => {
                                      value.tracks.removeAt(0),
                                    });
                              });
                              context.read<PlayerState>().flushPlaying();
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
                      index: index,
                      playlistInfo: snapshot.data,
                      elementOf: PlayingObject.playlist,
                      onAction: (TrackAction a) {
                        if (a == TrackAction.delete) {
                          deleteFromPlaylist(widget.info.fullPath, index)
                              .catchError((_) => showToast(
                                  context, "Failed to delete the track"));
                          setState(() {
                            playlist.then((value) => {
                                  value.tracks.removeAt(index),
                                });
                          });
                          context.read<PlayerState>().flushPlaying();
                        }
                      },
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      playlist.then((value) {
                        setTrackIndexPlaylist(
                            widget.info.fullPath, oldIndex, newIndex);
                        final item = value.tracks.removeAt(oldIndex);
                        value.tracks.insert(newIndex, item);
                      });
                    });
                    var state = context.read<PlayerState>();
                    if (state.currentPlaylist == snapshot.data) {
                      state.movePlaylistTrack(oldIndex, newIndex);
                    }
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
