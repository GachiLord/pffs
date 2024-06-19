import 'package:flutter/material.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/widgets/effect_modifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'dart:io';

class MiniPlayerAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MiniPlayerAppBar({super.key});

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  State<MiniPlayerAppBar> createState() => _MiniPlayerAppBarState();
}

class _MiniPlayerAppBarState extends State<MiniPlayerAppBar> {
  double? pos;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(builder: (context, state, child) {
      var currentPos = pos ?? state.pos.inMilliseconds.toDouble();
      var currentMax = state.duration?.inMilliseconds.toDouble() ?? 1;
      if (currentPos > currentMax) currentMax = currentPos;
      // check if positions are not zeros
      if (currentPos < 0) currentPos = 0;
      if (currentMax < 0) currentMax = 0;

      return AppBar(
          backgroundColor: Theme.of(context).colorScheme.onSecondary,
          title: (state.currentArtUriSync != null && !Platform.isAndroid)
              ? Row(
                  children: [
                    Material(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
 			isAntiAlias: true,
			filterQuality: FilterQuality.medium,
                        File.fromUri(state.currentArtUriSync!),
			fit: BoxFit.cover,
                        width: 45,
                        height: 35,
                      ),
                    ),
                    Flexible(
                        child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Text(
                        state.trackName ?? "",
                        overflow: TextOverflow.fade,
                      ),
                    ))
                  ],
                )
              : Text(
                  state.trackName ?? "",
                  overflow: TextOverflow.fade,
                ),
          actions: [
            CustomPopup(
                content: SizedBox(
                  width: 300,
                  height: 30,
                  child: VolumePicker(
                      onChanged: (v) => state.setVolume(v),
                      initial: state.volume),
                ),
                child: const Icon(Icons.volume_up)),
            IconButton(
                onPressed: () {
                  state.playPrevious();
                },
                icon: const Icon(Icons.skip_previous)),
            IconButton(
                onPressed: () {
                  state.playPause();
                },
                icon: state.playing
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow)),
            IconButton(
                onPressed: () {
                  state.playNext();
                },
                icon: const Icon(Icons.skip_next)),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: SizedBox(
              height: 15,
              child: SliderTheme(
                  data: SliderThemeData(trackShape: CustomTrackShape()),
                  child: Slider(
                    min: 0,
                    max: currentMax,
                    value: currentPos,
                    onChangeStart: (v) {
                      state.playPause();
                      setState(() {
                        pos = v;
                      });
                    },
                    onChanged: (v) {
                      setState(() {
                        pos = v;
                      });
                    },
                    onChangeEnd: (v) {
                      state.setPos(v.toInt());
                      setState(() {
                        pos = null;
                      });
                      state.playPause();
                    },
                  )),
            ),
          ));
    });
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx + 20;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width - 40;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
