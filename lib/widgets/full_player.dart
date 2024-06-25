import 'package:flutter/material.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/widgets/effect_modifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'dart:io';

class FullPlayer extends StatefulWidget implements PreferredSizeWidget {
  const FullPlayer({super.key});

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  double? pos;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(builder: (context, state, child) {
      return Scaffold(
        appBar: AppBar(
            leading: IconButton(
          padding: EdgeInsets.all(15),
          icon: Icon(Icons.arrow_back),
          iconSize: 25,
          onPressed: () {
            Navigator.of(context).pop();
          },
        )),
        body: Text("full player"),
      );
    });
  }
}
