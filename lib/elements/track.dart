import "dart:io";
import "package:flutter/material.dart";
import "package:pffs/logic/core.dart";
import "package:pffs/logic/state.dart";
import "package:pffs/logic/storage.dart";
import "package:pffs/util/informing.dart";
import "package:pffs/widgets/effect_modifier.dart";
import 'package:path/path.dart' as p;
import "package:provider/provider.dart";

enum TrackAction { delete, addToPlaylist }

class Track extends StatelessWidget {
  final String libraryPath;
  final MediaInfo trackInfo;
  final PlayingObject elementOf;
  final List<MediaInfo>? libraryTracks;
  final PlaylistConf? playlistInfo;
  final String? playlistRelativePath;
  final int? index;
  final Function(TrackAction)? onAction;

  const Track(
      {required this.trackInfo,
      this.index,
      this.libraryTracks,
      this.playlistInfo,
      this.playlistRelativePath,
      required this.libraryPath,
      required this.elementOf,
      required this.onAction,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, child) {
        var isCurrentTrack = (state.currentIndex == index &&
            state.playingObject == elementOf &&
            (state.playingObjectName ==
                    p.basenameWithoutExtension(playlistRelativePath ?? "") ||
                state.playingObject == PlayingObject.library));
        return ListTile(
          title: Text(
            trackInfo.name,
            style: TextStyle(
                color: isCurrentTrack
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isCurrentTrack ? FontWeight.w600 : null),
          ),
          onTap: () {
            if (elementOf == PlayingObject.library) {
              var p = state.playingObject;
              if (p == PlayingObject.nothing || p == PlayingObject.playlist) {
                var p = PlaylistConf(
                    tracks: libraryTracks!
                        .map((v) => TrackConf(relativePath: v.relativePath))
                        .toList(growable: false));
                state.setSequence(
                    p, PlayingObject.library, "Library", index ?? 0);
              }
              if (p == PlayingObject.library) {
                state.setSuqenceIndex(index!);
              }
            } else {
              var po = state.playingObject;
              if (po == PlayingObject.nothing || po == PlayingObject.library) {
                state.setSequence(
                    playlistInfo!,
                    PlayingObject.playlist,
                    p.basenameWithoutExtension(playlistRelativePath ?? ""),
                    index!);
              }
              if (po == PlayingObject.playlist) {
                if (state.currentPlaylist == playlistInfo) {
                  state.setSuqenceIndex(index!);
                } else {
                  state.setSequence(
                      playlistInfo!,
                      PlayingObject.playlist,
                      p.basenameWithoutExtension(playlistRelativePath ?? ""),
                      index!);
                }
              }
            }
          },
          trailing: Container(
              margin: EdgeInsetsDirectional.only(
                  top: 0,
                  bottom: 0,
                  start: 0,
                  end: (elementOf == PlayingObject.playlist &&
                          !Platform.isAndroid)
                      ? 10
                      : 0),
              child: child),
        );
      },
      child: TrackMenu(
        playlistRelativePath: playlistRelativePath,
        playlistInfo: playlistInfo,
        playlistIndex: index,
        trackInfo: trackInfo,
        libraryPath: libraryPath,
        onAction: onAction,
        elementOf: elementOf,
      ),
    );
  }
}

class TrackMenu extends StatelessWidget {
  final String libraryPath;
  final MediaInfo trackInfo;
  final Function(TrackAction)? onAction;
  final PlayingObject elementOf;
  final PlaylistConf? playlistInfo;
  final String? playlistRelativePath;
  final int? playlistIndex;
  late final Future<List<MediaInfo>> items = listPlaylists(libraryPath);

  TrackMenu(
      {required this.onAction,
      required this.trackInfo,
      required this.playlistRelativePath,
      required this.playlistIndex,
      required this.playlistInfo,
      required this.libraryPath,
      required this.elementOf,
      super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: const [],
        future: items,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          PopupMenuButton<TrackAction> output =
              PopupMenuButton(enabled: false, itemBuilder: (_) => []);
          if (snapshot.hasData) {
            output = PopupMenuButton<TrackAction>(
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<TrackAction>>[
                      PopupMenuItem<TrackAction>(
                        enabled: elementOf == PlayingObject.library,
                        value: TrackAction.addToPlaylist,
                        child: const Text("Add to playlist"),
                        onTap: () =>
                            addDialog(context, trackInfo, snapshot.data),
                      ),
                      PopupMenuItem<TrackAction>(
                        enabled: elementOf == PlayingObject.playlist,
                        child: const Text("Effects"),
                        onTap: () => showModifyDialog(
                            context,
                            playlistInfo!,
                            p.join(libraryPath, playlistRelativePath),
                            playlistIndex!),
                      ),
                      PopupMenuItem<TrackAction>(
                        value: TrackAction.delete,
                        child: elementOf == PlayingObject.playlist
                            ? const Text('Delete from playlist')
                            : const Text('Delete'),
                      ),
                    ],
                onSelected: (TrackAction a) {
                  if (onAction != null) onAction!(a);
                });
          }
          return output;
        });
  }
}

Future<void> addDialog(
    BuildContext context, MediaInfo track, List<MediaInfo> playlists) async {
  showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            title: const Text('Choose a playlist'),
            children: playlists
                .map((p) => SimpleDialogOption(
                      onPressed: () {
                        addToPlaylist(p.fullPath, track).then((_) {
                          if (context.mounted) {
                            context.read<PlayerState>().flushPlaying();
                          }
                        }).catchError((_) {
                          if (context.mounted) {
                            showToast(context, "Failed to save changes");
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(p.name),
                    ))
                .toList());
      });
}
