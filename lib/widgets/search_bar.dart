import 'package:flutter/material.dart';

class TrackSearchBar extends StatelessWidget {
  final Function(String)? onChange;
  final bool enabled;

  const TrackSearchBar({this.onChange, required this.enabled, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
          color: theme.onSecondary,
          border: BorderDirectional(
              bottom: BorderSide(color: theme.secondary, width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search",
          border: InputBorder.none,
        ),
        enabled: enabled,
        onChanged: (value) {
          if (onChange != null) {
            onChange!(value);
          }
        },
      ),
    );
  }
}
