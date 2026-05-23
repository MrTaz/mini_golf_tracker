import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_golf_tracker/course.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/main.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DatabaseConnection.setFirestoreInstanceForTesting(FakeFirebaseFirestore());
    UserProvider().resetForTesting();
    MainScaffold.skipPrecacheForTesting = true;
  });

  tearDown(() {
    DatabaseConnection.setFirestoreInstanceForTesting(null);
    UserProvider().resetForTesting();
  });

  testWidgets('created active game is resumable from the Activity Hub drawer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(skipAutoResume: true),
      ),
    );
    await pumpRoute(tester);

    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await pumpRoute(tester);

    expect(find.text('No current game'), findsOneWidget);
    await tester.tap(find.byKey(const Key('drawer-current-game')));
    await pumpRoute(tester);

    final gameCreateState =
        tester.state<GameCreateScreenState>(find.byType(GameCreateScreen));
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
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Integration Game');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Game'));
    await pumpRoute(tester);

    expect(find.byType(GameInprogressScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(GameInprogressScreen))).pop();
    await pumpRoute(tester);

    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await pumpRoute(tester);

    expect(find.text('Resume Active Game'), findsOneWidget);
    await tester.tap(find.byKey(const Key('drawer-current-game')));
    await pumpRoute(tester);

    expect(find.byType(GameInprogressScreen), findsOneWidget);
    expect(find.textContaining('Integration Course'), findsOneWidget);
  });
}
