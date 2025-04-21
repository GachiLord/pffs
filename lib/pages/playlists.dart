import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/util/informing.dart';
import 'package:pffs/logic/storage.dart';
import "playlist.dart";

class Playlists extends StatefulWidget {
  final String? path;
  final PlayerState playerState;

  @override
  State<Playlists> createState() => _PlaylistsState();

  const Playlists({super.key, required this.path, required this.playerState});
}

class _PlaylistsState extends State<Playlists> {
  late final Future<List<MediaInfo>> items = listPlaylists(widget.path);
  late bool _isVisible;
  late ScrollController _hideButtonController;

  @override
  initState() {
    super.initState();
    _isVisible = true;
    _hideButtonController = ScrollController();
    _hideButtonController.addListener(() {
      var prev = _isVisible;
      var cur = _hideButtonController.position.pixels !=
          _hideButtonController.position.maxScrollExtent;

      if (prev != cur) {
        setState(() {
          _isVisible = cur;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: items,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          Widget output = const Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
          );
          if (snapshot.hasData) {
            output = Scaffold(
                floatingActionButton: _isVisible
                    ? FloatingActionButton(
                        onPressed: () {
                          showTextDialogWithPath(context, widget.path!, "Create a playlist", (name, path) async {
                            try {
                              final conf = path != null ? createPlaylistFromDir(path!) as PlaylistConf: PlaylistConf(tracks: []);
                              final playlist = await createPlaylist(widget.path!, name, conf);

                              var value = await items;
                              value.add(playlist);
                            } catch(_) {
                              if (context.mounted) {
                                showToast(context, "Name exists or invalid");
                              }
                            }
                          });
                        },
                        child: const Icon(Icons.add),
                      )
                    : null,
                body: GridView.count(
                  controller: _hideButtonController,
                  primary: false,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: Platform.isAndroid ? 2 : 3,
                  children: snapshot.data
                      .map<Widget>((playlist) => RawMaterialButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Playlist(
                                        info: playlist,
                                        playerState: widget.playerState,
                                        libraryPath: widget.path!)),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GridTile(
                                footer: Material(
                                  color: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(4)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: GridTileBar(
                                    backgroundColor: Colors.black45,
                                    title: Text(playlist.name),
                                    trailing: PopupMenuButton<String>(
                                        icon: const Icon(Icons.menu),
                                        itemBuilder: (BuildContext context) =>
                                            <PopupMenuEntry<String>>[
                                              PopupMenuItem<String>(
                                                value: playlist.fullPath,
                                                child: const Text("Delete"),
                                                onTap: () {
                                                  showPrompt(context,
                                                      'Delete "${playlist.name}"?',
                                                      (ok) {
                                                    if (ok) {
                                                      deleteEntity(
                                                              playlist.fullPath)
                                                          .then((_) {
                                                        setState(() {
                                                          items.then((value) =>
                                                              value.remove(
                                                                  playlist));
                                                        });
                                                      }).catchError((_) {
                                                        if (context.mounted) {
                                                          showToast(context,
                                                              "Failed to delete the playlist");
                                                        }
                                                      });
                                                    }
                                                  });
                                                },
                                              ),
                                            ]),
                                  ),
                                ),
                                child: playlist.artUri != null
                                    ? Image.file(File.fromUri(playlist.artUri),
                                        fit: BoxFit.cover)
                                    : Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        child: const Icon(
                                          Icons.music_note_outlined,
                                          size: 80,
                                        ),
                                      ),
                              ),
                            ),
                          ) as Widget)
                      .toList(),
                ));
          } else if (snapshot.hasError) {
            print(snapshot.error);
            output = const Center(
              child: Text(
                "Incorrect path or insufficient permissions",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28),
              ),
            );
          }
          return output;
        });
  }
}
