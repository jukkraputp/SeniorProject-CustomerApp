import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class SelectOption extends StatefulWidget {
  const SelectOption(
      {super.key,
      required this.imageWidget,
      required this.price,
      required this.options,
      required this.name});

  final Image imageWidget;
  final String name;
  final double price;
  final dynamic options;

  @override
  State<SelectOption> createState() => _SelectOptionState();
}

class _SelectOptionState extends State<SelectOption> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
