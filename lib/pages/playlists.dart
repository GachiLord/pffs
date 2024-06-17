import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/util/informing.dart';
import 'package:pffs/logic/storage.dart';
import "playlist.dart";

class Playlists extends StatefulWidget {
  final String? path;

  @override
  State<Playlists> createState() => _PlaylistsState();

  const Playlists({super.key, required this.path});
}

class _PlaylistsState extends State<Playlists> {
  late final Future<List<MediaInfo>> items = listPlaylists(widget.path);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: const [],
        future: items,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          Widget output = const Text("loading");
          if (snapshot.hasData) {
            output = Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    showTextDialog(context, "Create a playlist", (name) {
                      createPlaylist(
                              widget.path!, name, PlaylistConf(tracks: []))
                          .then((info) => items.then((value) {
                                setState(() => value.add(info));
                              }))
                          .catchError((_) =>
                              showToast(context, "Name exists or invalid"));
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                body: GridView.count(
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
                                        libraryPath: widget.path!)),
                              );
                            },
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
                                                    }).catchError((_) => showToast(
                                                            context,
                                                            "Failed to delete the playlist"));
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
                                  : const Icon(
                                      Icons.music_note_outlined,
                                      size: 80,
                                    ),
                            ),
                          ) as Widget)
                      .toList(),
                ));
          } else if (snapshot.hasError) {
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
