import 'package:flutter/material.dart';

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
