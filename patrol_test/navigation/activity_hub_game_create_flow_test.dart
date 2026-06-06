// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mini_golf_tracker/features/courses/data/models/course.dart';
import 'package:mini_golf_tracker/core/network/database_connection.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_create_screen.dart';
import 'package:mini_golf_tracker/features/gameplay/presentation/screens/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/features/players/data/models/player.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpRoute(dynamic $) async {
  await $.pump();
  await $.pump(const Duration(milliseconds: 350));
  await $.pumpAndSettle();
}

Future<void> pumpUntilFound(
  dynamic $,
  Finder finder, {
  int attempts = 30,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await $.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
  });

  patrolTest('created active game is resumable from the Activity Hub drawer',
      ($) async {
    await $.pumpWidgetAndSettle(
      const MaterialApp(
        home: HomePage(skipAutoResume: true),
      ),
    );
    await pumpRoute($);

    expect($('Create a New Game'), findsOneWidget);
    await $('Create a New Game').tap();
    await pumpRoute($);

    final gameCreateState =
        $.tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
    gameCreateState.setSelectedCourseForTesting(Course(
      id: 'integration_course',
      name: 'Integration Course',
      numberOfHoles: 9,
      parStrokes: {for (var i = 1; i <= 9; i++) i: 3},
    ));
    gameCreateState.setSelectedPlayersForTesting([
      Player(
        id: 'p1',
        playerName: 'Ava Guest',
        nickname: 'Ava',
        ownerId: 'guest',
        totalScore: 0,
      ),
      Player(
        id: 'p2',
        playerName: 'Ben Guest',
        nickname: 'Ben',
        ownerId: 'guest',
        totalScore: 0,
      ),
    ]);
    await $.pump();

    await $(TextFormField).enterText('Integration Game');
    await $(find.widgetWithText(ElevatedButton, 'Create Game')).tap();
    await pumpRoute($);

    expect($(GameInprogressScreen), findsOneWidget);
    final createdGame = $.tester
        .widget<GameInprogressScreen>(find.byType(GameInprogressScreen))
        .currentGame;

    Navigator.of($.tester.element(find.byType(GameInprogressScreen))).pop();
    await pumpRoute($);
    await Game.saveLocalGame(createdGame);
    final savedGames =
        await Game.getLocallySavedGames(gameStatusTypes: ['started']);
    expect(savedGames, isNotEmpty);

    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: GameInprogressScreen(currentGame: savedGames.first!),
      ),
    );
    await pumpUntilFound($, $(GameInprogressScreen));

    expect($(GameInprogressScreen), findsOneWidget);
    expect($(find.textContaining('Integration Course')), findsOneWidget);
  });
}
