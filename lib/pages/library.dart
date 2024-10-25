import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pffs/elements/track.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/logic/storage.dart';
import 'package:pffs/util/informing.dart';
import 'package:pffs/widgets/search_bar.dart';
import 'package:provider/provider.dart';

class Library extends StatefulWidget {
  @override
  State<Library> createState() => _LibraryState();

  const Library({super.key});
}

class _LibraryState extends State<Library> {
  late final List<MediaInfo> items = [];

  late bool _isVisible;
  late ScrollController _hideButtonController;
  String query = "";

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

  Future<(List<MediaInfo>, List<MediaInfo>)> _fetchMedia(
      String libraryPath) async {
    return (await listTracks(libraryPath), await listPlaylists(libraryPath));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryState>(builder: (context, state, child) {
      return FutureBuilder<(List<MediaInfo>, List<MediaInfo>)>(
          future: _fetchMedia(state.libraryPath!),
          builder: (BuildContext ctx, AsyncSnapshot snapshot) {
            // render
            Widget output;
            if (snapshot.hasData) {
              // enumerate and filter values
              List<(int, MediaInfo)> data = List.empty(growable: true);
              for (var i = 0; i < snapshot.data.$1.length; i++) {
                data.add((i, snapshot.data.$1[i]));
              }
              data = data
                  .where((value) =>
                      value.$2.name
                          .contains(RegExp(query, caseSensitive: false)) ==
                      true)
                  .toList();
              output = ListView.builder(
                controller: _hideButtonController,
                itemCount: data.length,
                prototypeItem: data.isNotEmpty
                    ? Track(
                        index: data.first.$1,
                        libraryTracks: snapshot.data.$1,
                        libraryPath: state.libraryPath!,
                        playlists: snapshot.data.$2,
                        trackInfo: data.first.$2,
                        elementOf: PlayingObject.library,
                        onAction: (TrackAction a) => {
                          if (a == TrackAction.delete)
                            {
                              showPrompt(
                                  context,
                                  'Delete "${data.first.$2.name}"?',
                                  (ok) => {
                                        if (ok)
                                          {
                                            deleteEntity(data.first.$2.fullPath)
                                                .then((_) => {
                                                      setState(() {
                                                        data.removeAt(0);
                                                      }),
                                                    })
                                          }
                                      })
                            }
                        },
                      )
                    : null,
                itemBuilder: (context, index) {
                  return Track(
                    index: data[index].$1,
                    libraryTracks: snapshot.data.$1,
                    libraryPath: state.libraryPath!,
                    playlists: snapshot.data.$2,
                    trackInfo: data[index].$2,
                    elementOf: PlayingObject.library,
                    onAction: (TrackAction a) => {
                      if (a == TrackAction.delete)
                        {
                          showPrompt(
                              context,
                              'Delete "${data[index].$2.name}"?',
                              (ok) => {
                                    if (ok)
                                      {
                                        deleteEntity(data[index].$2.fullPath)
                                            .then((_) => {
                                                  setState(() {
                                                    data.removeAt(index);
                                                  }),
                                                })
                                      }
                                  })
                        }
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              output = const Center(
                child: Text(
                  "Incorrect path or insufficient permissions",
                  style: TextStyle(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              output = const Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return Scaffold(
                appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: TrackSearchBar(
                      onChange: (v) => setState(() => query = v),
                    )),
                floatingActionButton: _isVisible
                    ? FloatingActionButton(
                        onPressed: () {
                          void pathDialog(Directory dir) {
                            FilesystemPicker.open(
                              title: 'Choose library path',
                              context: context,
                              rootDirectory: dir,
                              fsType: FilesystemType.folder,
                            ).then((dir) {
                              if (dir != null) state.setLibraryPath(dir);
                            });
                          }

                          void setLibraryPath(Directory dir) {
                            dir.exists().then((value) {
                              if (value && !Platform.isWindows) {
                                pathDialog(dir);
                              } else {
                                showTextDialog(
                                    context,
                                    "Failed to invoke directory picker. Input library path manually",
                                    (v) => state.setLibraryPath(v));
                              }
                            });
                          }

                          if (Platform.isAndroid) {
                            Permission.manageExternalStorage
                                .request()
                                .then((r) {
                              setLibraryPath(Directory("/storage/emulated/0/"));
                            });
                          }
                          if (Platform.isLinux) {
                            setLibraryPath(Directory("/"));
                          }
                          if (Platform.isWindows) {
                            setLibraryPath(Directory("con"));
                          }
                        },
                        child: const Icon(Icons.folder),
                      )
                    : null,
                body: output);
          });
    });
  }
}
