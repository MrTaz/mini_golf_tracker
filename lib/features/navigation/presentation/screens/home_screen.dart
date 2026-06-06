import 'package:flutter/material.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:mini_golf_tracker/core/config/assets.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_create_screen.dart';
import 'package:mini_golf_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final user = UserProvider().loggedInUser;
    final String nickname = user?.nickname ?? "Guest";
    final bool isLoggedIn = user != null;

    Widget profileImage;
    if (isLoggedIn && user.email != null) {
      final gravatarImgUrl = Gravatar(user.email!).imageUrl(size: 120);
      profileImage = ClipOval(
        child: Image.network(
          gravatarImgUrl,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            "assets/images/avatars_3d_avatar_28.png",
            width: 120,
          ),
        ),
      );
    } else {
      profileImage = Image.asset(
        "assets/images/avatars_3d_avatar_28.png",
        width: 120,
      );
    }

    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              alignment: Alignment(.5, 1),
              image: AppImages.backgroundMainScreens,
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: const Color.fromARGB(187, 255, 255, 255),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: profileImage,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome, $nickname",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 35),
                      if (!isLoggedIn)
                        MaterialButton(
                          color: const Color(0xff4285f4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "User Login",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) {
                              return LoginScreen();
                            }));
                          },
                        )
                      else
                        MaterialButton(
                          color: Colors.redAccent,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          onPressed: () async {
                            await UserProvider().logout();
                          },
                        ),
                      const SizedBox(height: 35),
                      SizedBox(
                        width: 164,
                        child: Column(children: <Widget>[
                          MaterialButton(
                            child: const Text("Create a New Game",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                )),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                return const GameCreateScreen();
                              }));
                            },
                          )
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
