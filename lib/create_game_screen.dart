import 'package:flutter/material.dart';

class CreateGameScreen extends StatelessWidget {
  const CreateGameScreen({Key? key})
      : super(key: key); // Use the correct constructor syntax

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Game.'),
      ),
      body: const Center(
        child: Text('This is the next screen'),
      ),
    );
  }
}
