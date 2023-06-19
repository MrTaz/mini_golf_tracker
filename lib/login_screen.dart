import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const users = {
  'mrtaz28@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 50);

  Future<String?> _authUser(LoginData data) {
    debugPrint('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(data.name)) {
        return 'User not exists';
      }
      if (users[data.name] != data.password) {
        return 'Password does not match';
      }
      Future.microtask(() async {
        debugPrint('Setting email to ${data.name}');
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setString("email", data.name);
      });
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'User not exists';
      }
      return "";
    });
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 0.5;
    return Scaffold(
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
              additionalSignupFields: [
                const UserFormField(keyName: 'Username', icon: Icon(FontAwesomeIcons.userLarge)),
                UserFormField(
                  keyName: 'Date Of Birth',
                  fieldValidator: (value) {
                    return null;

                    //perform date validation here
                  },
                ),
                const UserFormField(keyName: 'First Name'),
                const UserFormField(keyName: 'Last Name'),
                const UserFormField(keyName: 'Email'),
                const UserFormField(keyName: 'Gender'),
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
              scrollable: true,
              loginProviders: <LoginProvider>[
                LoginProvider(
                  icon: FontAwesomeIcons.google,
                  // label: 'Google',
                  callback: () async {
                    debugPrint('start google sign in');
                    await Future.delayed(loginTime);
                    debugPrint('stop google sign in');
                    return null;
                  },
                ),
                LoginProvider(
                  icon: FontAwesomeIcons.facebookF,
                  // label: 'Facebook',
                  callback: () async {
                    debugPrint('start facebook sign in');
                    await Future.delayed(loginTime);
                    debugPrint('stop facebook sign in');
                    return null;
                  },
                ),
                LoginProvider(
                  icon: FontAwesomeIcons.snapchat,
                  callback: () async {
                    debugPrint('start snapchat sign in');
                    await Future.delayed(loginTime);
                    debugPrint('stop snapchat sign in');
                    return null;
                  },
                ),
                LoginProvider(
                  icon: FontAwesomeIcons.instagram,
                  callback: () async {
                    debugPrint('start instagram sign in');
                    await Future.delayed(loginTime);
                    debugPrint('stop instagram sign in');
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
        ));
  }
}
