import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/database_connection_error.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  // bool _isSnackOpen = false;
  // final Snapkit _snapkit = Snapkit();
  LoginScreen({super.key});
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Duration get loginTime => const Duration(milliseconds: 50);

  Future<void> _initializeLoggedInPlayer(Player loggedInPlayer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", loggedInPlayer.email!);
    await prefs.setString("loggedInUser", jsonEncode(loggedInPlayer));
    UserProvider().loggedInUser = loggedInPlayer;
  }

  Future<String?> _authUser(LoginData data) async {
    Utilities.debugPrintWithCallerInfo('Email: ${data.name}, Password: ${data.password}');
    try {
      final loggedInPlayer = await Player.getPlayerByEmailFromDB(data.name);
      if (loggedInPlayer != null) {
        _initializeLoggedInPlayer(loggedInPlayer);
      } else {
        throw DatabaseConnectionError('User was not found.');
      }
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("Login Error was caught: ${exception.toString()}");
      return 'An error occurred during user login.';
    }
    // Future.microtask(() async {
    //   Utilities.debugPrintWithCallerInfo('Setting email to ${data.name}');
    //   SharedPreferences pref = await SharedPreferences.getInstance();
    //   pref.setString("email", data.name);
    // });
    return null;
  }

  Future<void> _snapchatLoginUser() async {
    try {
      // bool installed = await _snapkit.isSnapchatInstalled;
      // if (installed) {
      //   await _snapkit.login();
      // } else if (!_isSnackOpen) {
      //   _isSnackOpen = true;
      //   _scaffoldMessengerKey.currentState!
      //       .showSnackBar(
      //         SnackBar(content: Text('Snapchat App not Installed.')),
      //       )
      //       .closed
      //       .then((_) {
      //     _isSnackOpen = false;
      //   });
      // }
    } on PlatformException catch (exception) {
      print(exception);
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    Utilities.debugPrintWithCallerInfo(
        'Signup Name: ${data.name}, Password: ${data.password}, ${data.additionalSignupData.toString()}');
    final email = data.name;
    final additionalData = data.additionalSignupData;
    final playerName = additionalData!['playerName'];
    final nickname = additionalData['nickname'];
    final phoneNumber = additionalData['phoneNumber'] ?? "";

    final newPlayer = Player.empty();

    try {
      Player loggedInPlayer = await newPlayer.createPlayer(playerName!, email!, phoneNumber, nickname!);
      if (loggedInPlayer != null) {
        _initializeLoggedInPlayer(loggedInPlayer);
      }
      return null;
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo("Signup Error was caught: ${exception.toString()}");
      return 'An error occurred during user registration.';
    }
  }

  Future<String> _recoverPassword(String name) {
    Utilities.debugPrintWithCallerInfo('Name: $name');
    return Future.delayed(loginTime).then((_) {
      return "";
    });
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 0.5;
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Mini Golf Tracker - Please login'),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              transform: Matrix4.translationValues(0, -100, 0.0),
              child: FlutterLogin(
                // title: "Test",
                // logo: const AssetImage('assets/images/1x1.png'),
                onLogin: _authUser,
                onSignup: _signupUser,
                userType: LoginUserType.email,
                showDebugButtons: (kDebugMode) ? true : false,
                scrollable: true,
                additionalSignupFields: const [
                  UserFormField(
                      keyName: 'playerName',
                      displayName: 'First Name',
                      icon: Icon(FontAwesomeIcons.userSecret),
                      userType: LoginUserType.name),
                  UserFormField(
                      keyName: 'nickname',
                      displayName: 'Display/Nick Name',
                      icon: Icon(FontAwesomeIcons.userNinja),
                      userType: LoginUserType.name),
                  UserFormField(
                      keyName: 'phoneNumber',
                      displayName: 'Phone Number',
                      icon: Icon(FontAwesomeIcons.mobile),
                      userType: LoginUserType.phone),
                ],
                theme: LoginTheme(
                    pageColorLight: Colors.transparent,
                    pageColorDark: Colors.transparent,
                    cardTheme: CardTheme(color: Colors.white.withOpacity(0.9)),
                    logoWidth: 0),
                // initialAuthMode: AuthMode.signup,
                // disableCustomPageTransformer: true,
                // loginAfterSignUp: true,
                // hideProvidersTitle: true,
                // scrollable: true,
                loginProviders: <LoginProvider>[
                  LoginProvider(
                    icon: FontAwesomeIcons.google,
                    // label: 'Google',
                    callback: () async {
                      Utilities.debugPrintWithCallerInfo('start google sign in');
                      await Future.delayed(loginTime);
                      Utilities.debugPrintWithCallerInfo('stop google sign in');
                      return null;
                    },
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.facebookF,
                    // label: 'Facebook',
                    callback: () async {
                      Utilities.debugPrintWithCallerInfo('start facebook sign in');
                      await Future.delayed(loginTime);
                      Utilities.debugPrintWithCallerInfo('stop facebook sign in');
                      return null;
                    },
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.snapchat,
                    callback: () async {
                      Utilities.debugPrintWithCallerInfo('start snapchat sign in');
                      await _snapchatLoginUser();
                      Utilities.debugPrintWithCallerInfo('stop snapchat sign in');
                      return null;
                    },
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.instagram,
                    callback: () async {
                      Utilities.debugPrintWithCallerInfo('start instagram sign in');
                      await Future.delayed(loginTime);
                      Utilities.debugPrintWithCallerInfo('stop instagram sign in');
                      return null;
                    },
                  ),
                ],
                onSubmitAnimationCompleted: () {
                  Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
                  // Navigator.of(context).pushReplacement(MaterialPageRoute(
                  //   builder: (context) => const HomePage(),
                  // ));
                },
                onRecoverPassword: _recoverPassword,
              ),
            ),
          )),
    );
  }
}
