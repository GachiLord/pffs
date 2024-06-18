import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pffs/elements/track.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/logic/storage.dart';
import 'package:pffs/util/informing.dart';
import 'package:provider/provider.dart';

class Library extends StatefulWidget {
  @override
  State<Library> createState() => _LibraryState();

  const Library({super.key});
}

class _LibraryState extends State<Library> {
  late final List<MediaInfo> items = [];
  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryState>(builder: (context, state, child) {
      return FutureBuilder(
          initialData: const [],
          future: listTracks(state.libraryPath),
          builder: (BuildContext ctx, AsyncSnapshot snapshot) {
            Widget output = const Text(
              "Loading",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28),
            );
            if (snapshot.hasData) {
              output = ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  return Track(
                    index: index,
                    libraryTracks: snapshot.data,
                    libraryPath: state.libraryPath!,
                    trackInfo: snapshot.data[index],
                    elementOf: ElementOf.library,
                    onAction: (TrackAction a) => {
                      if (a == TrackAction.delete)
                        {
                          showPrompt(
                              context,
                              'Delete "${snapshot.data[index].name}"?',
                              (ok) => {
                                    if (ok)
                                      {
                                        deleteEntity(
                                                snapshot.data[index].fullPath)
                                            .then((_) => {
                                                  setState(() {
                                                    snapshot.data
                                                        .removeAt(index);
                                                  }),
                                                  context
                                                      .read<PlayerState>()
                                                      .flushPlaying()
                                                })
                                            .catchError((_) => showToast(
                                                context,
                                                "Failed to delete the track")),
                                      }
                                  })
                        }
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              output = const Center(
                child: Text(
                  "Incorrect path or insufficient permissions",
                  style: TextStyle(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Scaffold(
                floatingActionButton: FloatingActionButton(
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
                      Permission.manageExternalStorage.request().then((r) {
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
                ),
                body: output);
          });
    });
  }
}
