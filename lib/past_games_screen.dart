import 'package:flutter/material.dart';

import 'past_games_list_view.dart';
import 'utilities.dart';

class PastGamesScreen extends StatelessWidget {
  const PastGamesScreen({Key? key}) : super(key: key); // Use the correct constructor syntax

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        body: Stack(children: [
          Utilities.backdropImageContinerWidget(),
          Padding(
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
          ),
        ]));
  }
}
