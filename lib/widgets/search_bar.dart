import 'package:flutter/material.dart';

class TrackSearchBar extends StatelessWidget {
  final Function(String)? onChange;

  const TrackSearchBar({this.onChange, super.key});

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
        onChanged: (value) {
          if (onChange != null) {
            onChange!(value);
          }
        },
      ),
    );
  }
}
