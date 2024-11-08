import 'package:flutter/material.dart';
import 'package:pffs/logic/state.dart';
import 'package:pffs/widgets/effect_modifier.dart';
import 'package:pffs/widgets/full_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart' as audio;

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
      // primary colour
      final primaryColour = Theme.of(context).colorScheme.primary;
      // loopMode icon
      Widget loopModeIcon;
      if (state.loopMode == audio.LoopMode.one) {
        loopModeIcon = Badge(
          backgroundColor: primaryColour,
          label: const Text('1'),
          child: const Icon(Icons.loop_rounded),
        );
      } else if (state.loopMode == audio.LoopMode.all) {
        loopModeIcon = Icon(Icons.loop_rounded, color: primaryColour);
      } else {
        loopModeIcon = const Icon(Icons.loop_rounded);
      }
      // actions
      var mobileActions = [
        IconButton(
            onPressed: () {
              state.playPrevious();
            },
            icon: const Icon(Icons.skip_previous_rounded)),
        IconButton(
            onPressed: () {
              state.playPause();
            },
            icon: state.playing
                ? const Icon(Icons.pause_rounded)
                : const Icon(Icons.play_arrow_rounded)),
        IconButton(
            onPressed: () {
              state.playNext();
            },
            icon: const Icon(Icons.skip_next_rounded)),
      ];
      var desktopActions = [
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: Text(
            state.pos.toString().split(".")[0].replaceFirst("0:", ""),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: CustomPopup(
              content: SizedBox(
                width: 250,
                height: 30,
                child: VolumePicker(
                    onChanged: (v) => state.setVolume(v),
                    initial: state.volume),
              ),
              child: const Icon(Icons.volume_up_rounded)),
        ),
        IconButton(
            onPressed: () {
              state.changeShuffleMode();
            },
            icon: const Icon(Icons.shuffle_rounded),
            color: state.shuffleOrder ? primaryColour : null),
        IconButton(
          onPressed: () {
            state.changeLoopMode();
          },
          icon: loopModeIcon,
        ),
        IconButton(
            onPressed: () {
              state.playPrevious();
            },
            icon: const Icon(Icons.skip_previous_rounded)),
        IconButton(
            onPressed: () {
              state.playPause();
            },
            icon: state.playing
                ? const Icon(Icons.pause_rounded)
                : const Icon(Icons.play_arrow_rounded)),
        IconButton(
            onPressed: () {
              state.playNext();
            },
            icon: const Icon(Icons.skip_next_rounded)),
      ];

      return AppBar(
          backgroundColor: Theme.of(context).colorScheme.onSecondary,
          title: state.currentTrack != null
              ? RawMaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(10)),
                  onPressed: () => Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, _, __) => const FullPlayer(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        final tween = Tween(begin: begin, end: end);
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: curve,
                        );

                        return SlideTransition(
                          position: tween.animate(curvedAnimation),
                          child: child,
                        );
                      })),
                  child:
                      (state.currentArtUriSync != null && !Platform.isAndroid)
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
                                    width: 65,
                                    height: 35,
                                  ),
                                ),
                                Flexible(
                                    child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    state.trackName ?? "",
                                    style: const TextStyle(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                              ],
                            )
                          : Text(
                              state.trackName ?? "",
                              style: const TextStyle(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                )
              : null,
          actions: Platform.isAndroid ? mobileActions : desktopActions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: state.currentTrack != null
                ? SizedBox(
                    height: Platform.isAndroid ? 1 : 9,
                    child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: Platform.isAndroid ? 4 : 8,
                          trackShape: CustomTrackShape(),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 8),
                          thumbShape: Platform.isAndroid
                              ? SliderComponentShape.noThumb
                              : const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                        ),
                        child: Slider(
                          min: 0,
                          max: currentMax,
                          value: currentPos,
                          onChangeStart: (v) {
                            if (Platform.isAndroid) return;

                            setState(() {
                              pos = v;
                            });
                          },
                          onChanged: (v) {
                            if (Platform.isAndroid) return;
                            setState(() {
                              pos = v;
                            });
                          },
                          onChangeEnd: (v) {
                            if (Platform.isAndroid) return;
                            state.setPos(v.toInt());
                            setState(() {
                              pos = null;
                            });
                          },
                        )),
                  )
                : Container(
                    decoration: BoxDecoration(
                        border: BorderDirectional(
                            bottom: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5)))),
          ));
    });
  }
}

class CustomTrackShape extends RectangularSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
