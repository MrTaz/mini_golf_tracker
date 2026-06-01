// ignore_for_file: non_const_argument_for_const_parameter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';


class LoginScreen extends StatefulWidget {
  final GoogleSignIn? googleSignIn;
  final String? promptMessage;

  const LoginScreen({super.key, this.googleSignIn, this.promptMessage});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late final GoogleSignIn googleSignInInstance;

  @override
  void initState() {
    super.initState();
    googleSignInInstance = widget.googleSignIn ?? GoogleSignIn.instance;
  }

  Duration get loginTime => const Duration(milliseconds: 50);

  @visibleForTesting
  Future<String?> authUser(LoginData data) async {
    Utilities.debugPrintWithCallerInfo(
        'Email: ${data.name}, Password: ${data.password}');
    try {
      final userCredential =
          await UserProvider().auth.signInWithEmailAndPassword(
                email: data.name,
                password: data.password,
              );

      if (userCredential.user != null) {
        final authUser = userCredential.user!;
        final loggedInPlayer =
            await Player.fetchPlayerForAuthUid(authUser.uid) ??
                await Player.claimPlayerForVerifiedAuthUser(
                  uid: authUser.uid,
                  email: authUser.email,
                  emailVerified: authUser.emailVerified,
                  phoneNumber: authUser.phoneNumber,
                );
        if (loggedInPlayer != null) {
          await UserProvider().login(loggedInPlayer);
        } else {
          return 'Verify an email or phone number to claim your player history.';
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

  @visibleForTesting
  Future<String?> signupUser(SignupData data) async {
    Utilities.debugPrintWithCallerInfo(
        'Signup Name: ${data.name}, Password: ${data.password}, ${data.additionalSignupData.toString()}');

    final additionalData = data.additionalSignupData!;
    final playerName = additionalData['playerName']!;
    final nickname = additionalData['nickname']!;
    final phoneNumber = additionalData['phoneNumber'] ?? "";

    try {
      Utilities.debugPrintWithCallerInfo(
          'Starting Firebase Auth Registration for ${data.name}');
      final userCredential =
          await UserProvider().auth.createUserWithEmailAndPassword(
                email: data.name!,
                password: data.password!,
              );

      if (userCredential.user != null) {
        Utilities.debugPrintWithCallerInfo(
            'Firebase Auth User Created: ${userCredential.user!.uid}');

        await userCredential.user!.sendEmailVerification();

        final existingPlayer =
            await Player.getPlayerByContactFromDB(data.name, phoneNumber);
        if (existingPlayer != null) {
          UserProvider().beginPendingClaim(existingPlayer);
          return 'Account created. Verify your email or phone to claim existing history.';
        }

        Player loggedInPlayer = await Player.createPlayer(
          playerName,
          nickname,
          email: data.name!,
          phoneNumber: phoneNumber,
          id: userCredential.user!.uid,
        );

        Utilities.debugPrintWithCallerInfo(
            'Firestore Player Profile Created: ${loggedInPlayer.id}');
        await UserProvider().login(loggedInPlayer);
        return null;
      }
      return 'Failed to create user account.';
    } on FirebaseAuthException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'FirebaseAuthException: ${e.code} - ${e.message}');
      return e.message ?? 'An error occurred during registration.';
    } catch (exception) {
      Utilities.debugPrintWithCallerInfo('Registration Error: $exception');
      return 'An error occurred during user registration.';
    }
  }

  @visibleForTesting
  Future<String?> recoverPassword(String name) async {
    Utilities.debugPrintWithCallerInfo('Name: $name');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _processSocialCredential(
    AuthCredential credential, {
    String? fallbackEmail,
    String? defaultDisplayName,
  }) async {
    final userCredential =
        await UserProvider().auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      final authUser = userCredential.user!;
      final emailToUse = authUser.email ?? fallbackEmail;
      var loggedInPlayer =
          await Player.fetchPlayerForAuthUid(authUser.uid) ??
              await Player.claimPlayerForVerifiedAuthUser(
                uid: authUser.uid,
                email: emailToUse,
                emailVerified: authUser.emailVerified,
                phoneNumber: authUser.phoneNumber,
              );
      if (loggedInPlayer == null) {
        final existingCandidate = await Player.getPlayerByContactFromDB(
          emailToUse,
          authUser.phoneNumber,
        );
        if (existingCandidate != null) {
          UserProvider().beginPendingClaim(existingCandidate);
          return 'Verify an email or phone number to claim your player history.';
        }

        Utilities.debugPrintWithCallerInfo(
            'Creating new player profile for social user: $emailToUse');
        final String displayName = (defaultDisplayName != null && defaultDisplayName.isNotEmpty)
            ? defaultDisplayName
            : (authUser.displayName ?? 'New User');

        loggedInPlayer = await Player.createPlayer(
          displayName,
          displayName.isNotEmpty && displayName != 'New User'
              ? displayName
              : 'user_${authUser.uid.substring(0, 5)}',
          email: emailToUse ?? '',
          phoneNumber: authUser.phoneNumber,
          id: authUser.uid,
        );

        if (authUser.photoURL != null) {
          loggedInPlayer.avatarImageLocation = authUser.photoURL;
        }
      }

      await UserProvider().login(loggedInPlayer);
    }
    return null;
  }

  @visibleForTesting
  Future<String?> handleGoogleLogin() async {
    try {
      if (widget.googleSignIn == null) {
        await googleSignInInstance.initialize(
          serverClientId:
              '114725116317-hcrn2kms85skt1kb0q4c73sgrj9fkc3u.apps.googleusercontent.com',
        );
      }
      final googleUser = await googleSignInInstance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _processSocialCredential(credential);
    } catch (e) {
      Utilities.debugPrintWithCallerInfo('Google Sign-In Error: $e');
      return 'Google Sign-In failed.';
    }
  }

  @visibleForTesting
  Future<String?> handleAppleLogin() async {
    try {
      WebAuthenticationOptions? webAuthenticationOptions;
      if (defaultTargetPlatform == TargetPlatform.android) {
        webAuthenticationOptions = WebAuthenticationOptions(
          clientId: 'org.dahome.miniGolfScoreTracker.signin',
          redirectUri: Uri.parse(
            'https://mini-golf-tracker-dahome.firebaseapp.com/__/auth/handler',
          ),
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: webAuthenticationOptions,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final String defaultName = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      return await _processSocialCredential(
        oauthCredential,
        fallbackEmail: credential.email,
        defaultDisplayName: defaultName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      Utilities.debugPrintWithCallerInfo(
          'Apple Sign-In cancelled or failed: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Apple Sign-In was cancelled.';
      }
      return 'Apple Sign-In failed: ${e.message}';
    } catch (e) {
      Utilities.debugPrintWithCallerInfo('Apple Sign-In Error: $e');
      return 'Apple Sign-In failed.';
    }
  }

  @visibleForTesting
  Future<String?> handleFacebookLogin() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.tokenString);

        return await _processSocialCredential(credential);
      } else if (result.status == LoginStatus.cancelled) {
        return 'Facebook Sign-In was cancelled.';
      } else {
        return result.message ?? 'Facebook Sign-In failed.';
      }
    } catch (e) {
      Utilities.debugPrintWithCallerInfo('Facebook Sign-In Error: $e');
      return 'Facebook Sign-In failed.';
    }
  }

  @visibleForTesting
  Future<String?> handleNotImplementedLogin() async {
    return 'Not implemented yet';
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text("Name: ${user.playerName}"),
                    Text("Nickname: ${user.nickname}"),
                    Text("Email: ${user.email}"),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await UserProvider().logout();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: const Text("Logout",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil("/", (_) => false);
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
            title: const Text('Putt Scorer - Please login'),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AppImages.backgroundMainScreens,
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                if (widget.promptMessage != null)
                  Container(
                    color: Colors.amber,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.black87),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.promptMessage!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    transform: Matrix4.translationValues(0, -100, 0.0),
                    child: FlutterLogin(
                onLogin: authUser,
                onSignup: signupUser,
                showDebugButtons: (kDebugMode) ? true : false,
                scrollable: true,
                additionalSignupFields: [
                  UserFormField(
                      keyName: 'playerName',
                      displayName: 'First Name',
                      icon: const FaIcon(FontAwesomeIcons.userSecret),
                      userType: LoginUserType.name),
                  UserFormField(
                      keyName: 'nickname',
                      displayName: 'Display/Nick Name',
                      icon: const FaIcon(FontAwesomeIcons.userNinja),
                      userType: LoginUserType.name),
                  UserFormField(
                      keyName: 'phoneNumber',
                      displayName: 'Phone Number',
                      icon: const FaIcon(FontAwesomeIcons.mobile),
                      userType: LoginUserType.phone),
                ],
                theme: LoginTheme(
                    pageColorLight: Colors.transparent,
                    pageColorDark: Colors.transparent,
                    cardTheme: CardTheme(color: Colors.white.withAlpha(240)),
                    logoWidth: 0),
                loginProviders: <LoginProvider>[
                  LoginProvider(
                    icon: FontAwesomeIcons.apple,
                    callback: handleAppleLogin,
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.google,
                    callback: handleGoogleLogin,
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.facebookF,
                    callback: handleFacebookLogin,
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.snapchat,
                    callback: handleNotImplementedLogin,
                  ),
                  LoginProvider(
                    icon: FontAwesomeIcons.instagram,
                    callback: handleNotImplementedLogin,
                  ),
                ],
                onSubmitAnimationCompleted: () {
                  Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
                },
                onRecoverPassword: recoverPassword,
              ),
            ),
          ),
        ],
      ),
    ),
  ));
  }
}
