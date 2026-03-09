import 'package:flutter/material.dart';
import 'package:flutter_pas_tabler_icons/flutter_pas_tabler_icons.dart';

void main() {
  runApp(const TablerIconsExample());
}

class TablerIconsExample extends StatelessWidget {
  const TablerIconsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabler Icons Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Tabler Icons Example')),
        body: const Center(
          child: Icon(TablerIcons.a_b, size: 64),
        ),
      ),
    );
  }
}
