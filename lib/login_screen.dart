import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Duration get loginTime => const Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    UserProvider().addListener(_onUserChanged);
  }

  @override
  void dispose() {
    UserProvider().removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _authUser(LoginData data) async {
    Utilities.debugPrintWithCallerInfo(
        'Email: ${data.name}, Password: ${data.password}');
    try {
      final userCredential = await UserProvider().auth.signInWithEmailAndPassword(
            email: data.name,
            password: data.password,
          );
      
      if (userCredential.user != null) {
        final loggedInPlayer = await Player.getPlayerByEmailFromDB(data.name);
        if (loggedInPlayer != null) {
          await UserProvider().login(loggedInPlayer);
        } else {
          return 'User profile not found in database.';
        }
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during login.';
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "Login Error was caught: ${exception.toString()}");
      return 'An error occurred during user login.';
    }
    return null;
  }

  Future<String?> _signupUser(SignupData data) async {
    Utilities.debugPrintWithCallerInfo(
        'Signup Name: ${data.name}, Password: ${data.password}, ${data.additionalSignupData.toString()}');
    final email = data.name!;
    final additionalData = data.additionalSignupData!;
    final playerName = additionalData['playerName']!;
    final nickname = additionalData['nickname']!;
    final phoneNumber = additionalData['phoneNumber'] ?? "";

    try {
      final userCredential = await UserProvider().auth.createUserWithEmailAndPassword(
            email: email,
            password: data.password!,
          );

      if (userCredential.user != null) {
        Player loggedInPlayer = await Player.createPlayer(
            playerName, email, phoneNumber, nickname);
        await UserProvider().login(loggedInPlayer);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during registration.';
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo(
          "Signup Error was caught: ${exception.toString()}");
      return 'An error occurred during user registration.';
    }
  }

  Future<String?> _recoverPassword(String name) {
    Utilities.debugPrintWithCallerInfo('Name: $name');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _handleGoogleLogin() async {
    Utilities.debugPrintWithCallerInfo('Starting Google Sign-In Simulation');
    
    // In a real app, this would use google_sign_in package
    // For simulation/mocking, we can use a fixed email
    const String googleEmail = "google_user@example.com";
    
    try {
      // Check if user exists in Firestore first (or create if simulation)
      var player = await Player.getPlayerByEmailFromDB(googleEmail);
      player ??= await Player.createPlayer(
          "Google User", googleEmail, "555-0199", "Googler");

      // In tests/simulation, we might want to "force" a login if we can't do real Google Auth
      // Here we just ensure UserProvider is updated.
      // If we are in a mock environment (e.g. tests), UserProvider().auth is a MockFirebaseAuth
      // and we can't easily "simulate" the Google popup, but we can sign in anonymously or with a fake credential.
      
      await UserProvider().login(player);
      Utilities.debugPrintWithCallerInfo('Google Sign-In Simulated Successfully');
      return null;
    } catch (e) {
      return "Google Sign-In failed: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserProvider().loggedInUser;
    final bool isLoggedIn = user != null;

    if (isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Details'),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AppImages.backgroundMainScreens,
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              color: Colors.white.withAlpha(230),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Already Logged In",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text("Name: ${user.playerName}"),
                    Text("Nickname: ${user.nickname}"),
                    Text("Email: ${user.email}"),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await UserProvider().logout();
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil("/", (_) => false);
                      },
                      child: const Text("Back to Home"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Mini Golf Tracker - Please login'),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AppImages.backgroundMainScreens,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              transform: Matrix4.translationValues(0, -100, 0.0),
              child: FlutterLogin(
                onLogin: _authUser,
                onSignup: _signupUser,
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
                    cardTheme: CardTheme(color: Colors.white.withAlpha(240)),
                    logoWidth: 0),
                loginProviders: <LoginProvider>[
                  LoginProvider(
                    icon: FontAwesomeIcons.google,
                    callback: _handleGoogleLogin,
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.facebookF,
                    callback: () async {
                      return "Facebook login not implemented";
                    },
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.snapchat,
                    callback: () async {
                      return "Snapchat login not implemented";
                    },
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.instagram,
                    callback: () async {
                      return "Instagram login not implemented";
                    },
                  ),
                ],
                onSubmitAnimationCompleted: () {
                  Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
                },
                onRecoverPassword: _recoverPassword,
              ),
            ),
          )),
    );
  }
}
