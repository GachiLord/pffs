import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:pffs/logic/state.dart';
import 'package:pffs/widgets/effect_modifier.dart';
import 'package:pffs/widgets/mini_player.dart' show CustomTrackShape;
import 'package:provider/provider.dart';
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
          padding: const EdgeInsets.all(15),
          icon: const Icon(Icons.arrow_back),
          iconSize: 25,
          onPressed: () {
            Navigator.of(context).pop();
          },
        )),
        body: Center(
            child: Column(
          children: [
            _ArtImage(uri: state.currentArtUriSync),
            Container(
              padding: const EdgeInsets.only(top: 15),
              child: _TrackInfo(
                trackName: state.trackName ?? "Unknown",
                trackArtist: state.playingObjectName ?? "Unknown",
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 15),
              child: _Controls(state: state),
            )
          ],
        )),
      );
    });
  }
}

class _ArtImage extends StatelessWidget {
  final Uri? uri;

  const _ArtImage({required this.uri});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.65;
    final w = MediaQuery.sizeOf(context).width * 0.85;
    final radius = BorderRadius.circular(15);

    return uri != null
        ? Material(
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
                isAntiAlias: true,
                filterQuality: FilterQuality.high,
                File.fromUri(uri!),
                fit: BoxFit.cover,
                height: h,
                width: w),
          )
        : ClipRRect(
            borderRadius: radius,
            child: Container(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.music_note_outlined,
                size: h,
              ),
            ),
          );
  }
}

class _TrackInfo extends StatelessWidget {
  final String trackName;
  final String trackArtist;

  const _TrackInfo({
    required this.trackName,
    required this.trackArtist,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          trackName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 35,
          ),
        ),
        Text(
          trackArtist,
          style: const TextStyle(fontSize: 25),
        ),
      ],
    );
  }
}

class _Controls extends StatefulWidget {
  final PlayerState state;

  const _Controls({required this.state});

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  double? pos;

  @override
  Widget build(BuildContext context) {
    // helper vars
    final w = MediaQuery.sizeOf(context).width * 0.85;
    var state = widget.state;
    // pos
    var currentPos = pos ?? state.pos.inMilliseconds.toDouble();
    var currentMax = state.duration?.inMilliseconds.toDouble() ?? 1;
    if (currentPos > currentMax) currentMax = currentPos;
    // check if positions are not zeros
    if (currentPos < 0) currentPos = 0;
    if (currentMax < 0) currentMax = 0;
    // theme
    // primary colour
    final colours = Theme.of(context).colorScheme;
    final primaryColour = colours.primary;
    final secondaryColour = colours.secondary;
    // loopMode icon
    Widget loopModeIcon;
    if (state.loopMode == LoopMode.one) {
      loopModeIcon = Badge(
        backgroundColor: primaryColour,
        label: const Text('1'),
        child: const Icon(Icons.loop_rounded),
      );
    } else if (state.loopMode == LoopMode.all) {
      loopModeIcon = Icon(Icons.loop_rounded, color: primaryColour);
    } else {
      loopModeIcon = const Icon(Icons.loop_rounded);
    }

    return SizedBox(
      width: w,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  trackShape: CustomTrackShape(),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: currentMax,
                  value: currentPos,
                  onChangeStart: (v) {
                    if (state.playing) state.playPause();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.pos.toString().split(".")[0].replaceFirst("0:", ""),
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                state.duration.toString().split(".")[0].replaceFirst("0:", ""),
                style: const TextStyle(fontSize: 16),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  state.playPrevious();
                },
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 75,
              ),
              IconButton(
                onPressed: () {
                  state.playPause();
                },
                icon: state.playing
                    ? const Icon(Icons.pause_rounded)
                    : const Icon(Icons.play_arrow_rounded),
                iconSize: 75,
              ),
              IconButton(
                onPressed: () {
                  state.playNext();
                },
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 75,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPopup(
                  content: SizedBox(
                    width: 250,
                    height: 30,
                    child: VolumePicker(
                        onChanged: (v) => state.setVolume(v),
                        initial: state.volume),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: secondaryColour,
                    size: 30,
                  )),
              IconButton(
                onPressed: () {
                  state.changeShuffleMode();
                },
                icon: const Icon(Icons.shuffle_rounded),
                color: state.shuffleOrder ? primaryColour : null,
                iconSize: 30,
              ),
              IconButton(
                onPressed: () {
                  state.changeLoopMode();
                },
                icon: loopModeIcon,
                iconSize: 30,
              ),
            ],
          )
        ],
      ),
    );
  }
}
