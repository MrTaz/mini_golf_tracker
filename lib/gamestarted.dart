import 'package:flutter/material.dart';

class GameStarted extends StatelessWidget {
  const GameStarted({Key? key})
      : super(key: key); // Use the correct constructor syntax

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Screen'),
      ),
      body: const Center(
        child: Text('This is the next screen'),
      ),
    );
  }
}
