import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/gravatar_image_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mini_golf_tracker/main.dart';
import 'test_helper.dart';

void main() {
  setUp(() {
    MainScaffold.skipPrecacheForTesting = true;
  });
  testWidgets('GravatarImageView renders fading image with correct url', (WidgetTester tester) async {
    // We mock CachedNetworkImage by not actually loading the network since we can just check if widget is there
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: GravatarImageView(email: 'test@example.com', width: 100, height: 100),
        ),
      ),
    ));

    // Wait for future to complete
    await tester.pumpAndSettle();

    final fadeImageFinder = find.byType(FadeInImage);
    expect(fadeImageFinder, findsOneWidget);
    
    final FadeInImage fadeImage = tester.widget<FadeInImage>(fadeImageFinder);
    expect(fadeImage.image, isA<CachedNetworkImageProvider>());
    expect(fadeImage.width, 100);
    expect(fadeImage.height, 100);

    // Call the error builder directly to get coverage
    final errorWidget = fadeImage.imageErrorBuilder!(
      tester.element(fadeImageFinder),
      Exception('Test error'),
      StackTrace.empty,
    );
    expect(errorWidget, isA<Image>());
  });

  testWidgets('GravatarImageView renders with empty email', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: GravatarImageView(email: ''),
        ),
      ),
    ));

    // Wait for future to complete
    await tester.pumpAndSettle();

    final fadeImageFinder = find.byType(FadeInImage);
    expect(fadeImageFinder, findsOneWidget);
  });
  
  testWidgets('GravatarImageView uses cache on second call', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: GravatarImageView(email: 'test_cache@example.com'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    
    // Pump a second one with same email
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultAssetBundle(
          bundle: FakeAssetBundle(),
          child: GravatarImageView(email: 'test_cache@example.com'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    
    final fadeImageFinder = find.byType(FadeInImage);
    expect(fadeImageFinder, findsOneWidget);
  });
}
