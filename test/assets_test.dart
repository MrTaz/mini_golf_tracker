import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/assets.dart';

void main() {
  test('AppImages constants', () {
    expect(AppImages.backgroundLoggedIn.assetName, 'assets/images/loggedin_background_2.png');
    expect(AppImages.backgroundMainScreens.assetName, 'assets/images/background.jpeg');
  });
}
