import 'package:flutter/material.dart';

Future<dynamic> confirmation(BuildContext context,
    {required void Function()? onYes,
    required void Function()? onNo,
    Widget? title,
    Widget? content}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: <Widget>[
          TextButton(onPressed: onNo, child: const Text('No')),
          TextButton(onPressed: onYes, child: const Text('Yes'))
        ],
      );
    },
  );
}
