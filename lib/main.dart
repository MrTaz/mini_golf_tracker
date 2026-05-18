import 'package:flutter/material.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/claim_account_screen.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseConnection.initialize();
  await UserProvider().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
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
    UserProvider().removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    UserProvider().addListener(_onUserChanged);
    _updateState();
  }

  void _onUserChanged() {
    if (mounted) {
      setState(() {
        _updateState();
      });
    }
  }

  void _updateState() {
    final user = UserProvider().loggedInUser;
    if (user != null) {
      body = const DashboardScreen();
      changeProfileImage();
    } else if (UserProvider().pendingClaimPlayer != null) {
      body = const ClaimAccountScreen();
    } else {
      body = const HomeScreen();
    }
  }

  void changeBodyCallback(Widget nextPage) {
    body = nextPage;
  }

  void logout() async {
    await UserProvider().logout();
  }

  void changeProfileImage() async {
    final loggedInUser = UserProvider().loggedInUser;
    if (!mounted || loggedInUser == null) {
      return;
    }
    setState(() {
      if (loggedInUser.avatarImageLocation != null &&
          loggedInUser.avatarImageLocation!.isNotEmpty) {
        profileImage = Image.network(loggedInUser.avatarImageLocation!);
      } else {
        final gravatarImgUrl =
            Gravatar(loggedInUser.email ?? "").imageUrl(size: 120);
        profileImage = Image.network(gravatarImgUrl);
      }
    });
  }

  List<Widget> _buildDrawerList(BuildContext context) {
    List<Widget> children = [];
    if (UserProvider().loggedInUser != null) {
      children.addAll(_buildUserAccounts(context));
    }
    return children;
  }

  List<Widget> _buildUserAccounts(BuildContext context) {
    final loggedInPlayer = UserProvider().loggedInUser;
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
