import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/features/navigation/presentation/screens/home_screen.dart';

void main() {
  testWidgets('logged-out home screen shows entry actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('User Login'), findsOneWidget);
    expect(find.text('Create a New Game'), findsOneWidget);
  });
}
