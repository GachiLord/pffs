import 'package:flutter/material.dart';
import 'package:pffs/logic/core.dart';
import 'package:pffs/logic/storage.dart';
import 'package:pffs/util/informing.dart';

void showModifyDialog(BuildContext context, PlaylistConf playlist,
    String playlistFullPath, int trackIndex) {
  // TODO: add sync with global state
  var track = playlist.tracks[trackIndex];
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Add effects"),
        content: SingleChildScrollView(
            child: ListBody(
          children: [
            ListBody(
              children: [
                const Text(
                  "Volume",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                EnabledSwitch(
                    initial: track.volume.isActive,
                    onChanged: (v) => track.volume.isActive = v),
                VolumePicker(
                    onChanged: (v) => track.volume.startVolume = v,
                    initial: track.volume.startVolume),
                VolumePicker(
                    onChanged: (v) => track.volume.endVolume = v,
                    initial: track.volume.endVolume),
                TextFormField(
                    initialValue: track.volume.transitionTimeSeconds.toString(),
                    decoration:
                        const InputDecoration(labelText: "Time to set volume"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      var parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        track.volume.transitionTimeSeconds = parsed;
                      }
                    })
              ],
            ),
            ListBody(
              children: [
                const Text("Play boundaries",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                EnabledSwitch(
                    initial: track.skip.isActive,
                    onChanged: (v) => track.skip.isActive = v),
                TextFormField(
                    initialValue: track.skip.start.toString(),
                    decoration: const InputDecoration(
                        labelText: "Enter start bound in seconds"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      var parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        track.skip.start = parsed;
                      }
                    }),
                TextFormField(
                    initialValue: track.skip.end.toString(),
                    decoration: const InputDecoration(
                        labelText: "Enter end bound in seconds"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      var parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        track.skip.end = parsed;
                      }
                    }),
              ],
            ),
          ],
        )),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Save'),
            onPressed: () {
              setTrackPlaylist(playlistFullPath, trackIndex, track).catchError(
                  (e) => showToast(context, "Failed to update effects"));
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      );
    },
  );
}

class VolumePicker extends StatefulWidget {
  final Function(double) onChanged;
  final double initial;

  const VolumePicker(
      {super.key, required this.onChanged, required this.initial});

  @override
  State<VolumePicker> createState() => _VolumePickerState();
}

class _VolumePickerState extends State<VolumePicker> {
  double value = 0.0;

  @override
  void initState() {
    value = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      min: 0.0,
      max: 1.0,
      value: value,
      onChanged: (v) {
        setState(() {
          widget.onChanged(v);
          value = v;
        });
      },
    );
  }
}

class EnabledSwitch extends StatefulWidget {
  final bool initial;
  final Function(bool) onChanged;

  const EnabledSwitch(
      {super.key, required this.initial, required this.onChanged});

  @override
  State<EnabledSwitch> createState() => _EnabledSwitchState();
}

class _EnabledSwitchState extends State<EnabledSwitch> {
  bool light = true;

  @override
  void initState() {
    light = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: const Text(
          "Enable/Disable",
          style: TextStyle(fontSize: 16),
        ),
        trailing: Switch(
            value: light,
            onChanged: (v) {
              setState(() {
                light = v;
              });
              widget.onChanged(v);
            }));
  }
}
