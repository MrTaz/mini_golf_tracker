import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

class PastGamesScreen extends StatelessWidget {
  const PastGamesScreen({Key? key}) : super(key: key); // Use the correct constructor syntax

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                alignment: Alignment(1, 1),
                image: AssetImage("assets/images/loggedin_background_2.png"),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    PastGamesListView(),
                  ],
                ),
              ),
            )));
  }
}
