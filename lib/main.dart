import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseConnection.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Mini Golf Tracker',
        theme: ThemeData(
          canvasColor: const Color(0xFFfafafa),
          fontFamily: 'Merriweather',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)
              .copyWith(secondary: const Color(0xFF009688)),
        ),
        home: const HomePage(),
        initialRoute: '/',
        routes: {
          '/players': (context) {
            return const PlayersScreen();
          }
        });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  MainScaffold createState() => MainScaffold();
}

class MainScaffold extends State<HomePage> {
  MainScaffold();

  Widget body = const HomeScreen();
  Player? loggedInPlayer;
  Image profileImage = Image.asset(
    "assets/images/avatars_3d_avatar_28.png",
    width: 120,
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    precacheImage(AppImages.backgroundMainScreens, context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // backgroundImage = const AppImage.backgroundMainScreens;
    _initializeLoggedInPlayer();
    // Future.microtask(() async {
    //   WidgetsFlutterBinding.ensureInitialized();
    //   final prefs = await SharedPreferences.getInstance();
    //   final email = prefs.getString("email");
    //   setState(() async {
    //     Utilities.debugPrintWithCallerInfo('Setting init state, $email');
    //     if (email == null) {
    //       logout();
    //     } else {
    //       loggedInPlayer = await Player.empty().getPlayerByEmail(email);
    //       isLoggedIn(true);
    //       changeProfileImage();
    //       body = const DashboardScreen();
    //     }
    //   });
    // });
  }

  void changeBodyCallback(Widget nextPage) {
    body = nextPage;
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    setState(() {
      loggedInPlayer = null;
      body = const HomeScreen();
      final currentState = _scaffoldKey.currentState;
      if (currentState != null && currentState.isDrawerOpen) {
        _scaffoldKey.currentState!.openEndDrawer();
      }
    });
  }

  void changeProfileImage() async {
    Utilities.debugPrintWithCallerInfo('Getting email for gravatar');
    final pref = await SharedPreferences.getInstance();
    final loggedInEmail = pref.getString("email");
    if (!mounted || loggedInEmail == null || loggedInEmail.isEmpty) {
      return;
    }
    setState(() {
      final gravatarImgUrl = Gravatar(loggedInEmail).imageUrl(size: 120);
      profileImage = Image.network(gravatarImgUrl);
    });
  }

  Future<void> _initializeLoggedInPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    if (email == null) {
      logout();
    } else {
      try {
        String? loggedInUserJson = prefs.getString("loggedInUser");
        if (loggedInUserJson != null) {
          loggedInPlayer = Player.fromJson(jsonDecode(loggedInUserJson));
          if (loggedInPlayer != null) {
            UserProvider().loggedInUser = loggedInPlayer;
            await loggedInPlayer?.loadUserPlayers();
            changeProfileImage();
            if (!mounted) {
              return;
            }
            setState(() {
              body = const DashboardScreen();
            });
          }
        }
      } catch (error) {
        Utilities.debugPrintWithCallerInfo(
            "Error fetching logged-in player: $error");
        logout();
      }
    }
  }

  List<Widget> _buildDrawerList(BuildContext context) {
    List<Widget> children = [];
    if (loggedInPlayer != null) {
      children.addAll(_buildUserAccounts(context));
    }
    return children;
  }

  List<Widget> _buildUserAccounts(BuildContext context) {
    return [
      UserAccountsDrawerHeader(
          accountName: Row(children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(loggedInPlayer?.playerName ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  loggedInPlayer?.nickname ?? "",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            )
          ]),
          accountEmail: Text(loggedInPlayer?.email ?? ""),
          currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.teal,
              child: ClipOval(child: profileImage)),
          otherAccountsPictures: <Widget>[
            GestureDetector(
              onTap: () => logout(),
              child: Semantics(
                label: 'Logout',
                child: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(FontAwesomeIcons.lock),
                ),
              ),
            )
          ])
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          precacheImage(AppImages.backgroundMainScreens, context),
        ]),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.connectionState != ConnectionState.waiting) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: const Text('Mini Golf Tracker'),
              ),
              drawer: Drawer(
                child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: _buildDrawerList(context)),
              ),
              body: body,
            );
          } else {
            return Container(
              color: Colors.green[600],
              child: Center(
                child: BouncyAnimation(
                    duration: const Duration(seconds: 1),
                    lift: 80,
                    ratio: 0.25,
                    pause: 0.01,
                    child: CustomPaint(
                        painter: GolfBallPainter(),
                        child: const SizedBox(width: 100, height: 100))),
              ),
            );
          }
        });
  }
}
