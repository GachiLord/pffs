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
                body: ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(snapshot.data[index].name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Playlist(
                                    info: snapshot.data[index],
                                    libraryPath: widget.path!)),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: snapshot.data[index].fullPath,
                              child: const Text("Delete"),
                              onTap: () {
                                showPrompt(context,
                                    'Delete "${snapshot.data[index].name}"?',
                                    (ok) {
                                  if (ok) {
                                    deleteEntity(snapshot.data[index].fullPath)
                                        .then((_) {
                                      setState(() {
                                        items.then(
                                            (value) => value.removeAt(index));
                                      });
                                    }).catchError((_) => showToast(context,
                                            "Failed to delete the playlist"));
                                  }
                                });
                              },
                            ),
                          ],
                        ));
                  },
                ));
          } else if (snapshot.hasError) {
            output = const Center(
              child: Text(
                "Incorrect path or insufficient permissions",
                style: TextStyle(fontSize: 28),
              ),
            );
          }
          return output;
        });
  }
}
