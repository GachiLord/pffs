import 'package:flutter/material.dart';
import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';

void showToast(BuildContext context, String text) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

void showPrompt(BuildContext context, String title, Function(bool) onChosen) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: const Text(
          'This action cannot be undone. Are you sure?',
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () {
              onChosen(false);
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Perform'),
            onPressed: () {
              onChosen(true);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showTextDialog(
    BuildContext context, String title, Function(String) onInput) {
  var input = "";
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(onChanged: (value) {
          input = value;
        }),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Perform'),
            onPressed: () {
              onInput(input);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


void showTextDialogWithPath(
    BuildContext context, String libraryPath, String title, Function(String, String?) onInput) {
  var input = "";
  var playlistDir;

  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              TextButton(
                child: Text("Provide optional playlist directory path"),
                onPressed: () {
                  void pathDialog(Directory dir) {
                    FilesystemPicker.open(
                      title: 'Playlist directory path',
                      context: context,
                      rootDirectory: dir,
                      fsType: FilesystemType.folder,
                    ).then((dir) {
                      if (dir != null) {
                          playlistDir = dir;
                      }
                    });
                  }

                  void setLibraryPath(Directory dir) {
                    dir.exists().then((value) {
                      if (value && !Platform.isWindows) {
                        pathDialog(dir);
                      } else {
                        showTextDialog(context,
                            "Failed to invoke directory picker. Input the relative path manually",
                            (v) {
                            playlistDir = v;
                        });
                      }
                    });
                  }

                  if (Platform.isAndroid) {
                    setLibraryPath(Directory(libraryPath));
                  }
                  if (Platform.isLinux) {
                    setLibraryPath(Directory(libraryPath));
                  }
                  if (Platform.isWindows) {
                    setLibraryPath(Directory(libraryPath));
                  }
              }
              ),
              TextField(onChanged: (value) {
                input = value;
              })
            ]
          ),
        ), 
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Perform'),
            onPressed: () {
              onInput(input, playlistDir);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
