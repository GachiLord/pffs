import "package:flutter/material.dart";

enum ElementOf { library, playlist }

class Playlist extends StatelessWidget {
  final String name;

  const Playlist({required this.name, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
