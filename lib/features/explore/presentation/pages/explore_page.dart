import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StayEasy')),
      body: const Center(child: Text('The Flutter foundation is ready.')),
    );
  }
}
