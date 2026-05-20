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
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/past_games_screen.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/scheduled_games_screen.dart';
import 'package:mini_golf_tracker/utilities.dart';


Future<void> main() async {
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

  static bool skipPrecacheForTesting = false;

  Widget body = const HomeScreen();
  Image profileImage = Image.asset(
    "assets/images/avatars_3d_avatar_28.png",
    width: 120,
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<void>>? _precacheFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (skipPrecacheForTesting) {
      _precacheFuture = Future.value(<void>[]);
    } else {
      _precacheFuture ??= Future.wait([
        precacheImage(AppImages.backgroundMainScreens, context),
      ]);
    }
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
    _checkAndAutoResumeActiveGame();
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

  void _checkAndAutoResumeActiveGame() async {
    final activeGames = await Game.getLocallySavedGames(gameStatusTypes: ['started']);
    if (activeGames.isNotEmpty && activeGames.first != null) {
      if (mounted && UserProvider().pendingClaimPlayer == null) {
        setState(() {
          body = GameInprogressScreen(currentGame: activeGames.first!);
        });
      }
    }
  }

  void changeBodyCallback(Widget nextPage) {
    if (mounted) {
      setState(() {
        body = nextPage;
      });
    }
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
    final user = UserProvider().loggedInUser;
    List<Widget> list = [];
    if (user != null) {
      list.addAll(_buildUserAccounts(context));
    } else {
      list.add(
        const UserAccountsDrawerHeader(
          accountName: Text("Guest Profile"),
          accountEmail: null,
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      );
    }

    list.add(
      FutureBuilder<List<Game?>>(
        future: Game.getLocallySavedGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final allGames = snapshot.data ?? [];
          final nonNullGames = allGames.whereType<Game>().toList();

          final activeGames = nonNullGames.where((g) => g.status == 'started').toList();
          final hasActive = activeGames.isNotEmpty;

          final upcomingGames = nonNullGames
              .where((g) => g.status == 'unstarted_game')
              .toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          final topUpcoming = upcomingGames.take(5).toList();

          final recentGames = nonNullGames
              .where((g) => g.status == 'completed')
              .toList()
            ..sort((a, b) {
              final aTime = a.completedTime ?? a.scheduledTime;
              final bTime = b.completedTime ?? b.scheduledTime;
              return bTime.compareTo(aTime);
            });
          final topRecent = recentGames.take(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                key: const Key('drawer-current-game'),
                leading: Icon(
                  hasActive ? Icons.play_circle_filled : Icons.play_disabled,
                  color: hasActive ? Colors.green : Colors.grey,
                ),
                title: Text(hasActive ? "Resume Active Game" : "No current game"),
                onTap: () {
                  Navigator.pop(context);
                  if (hasActive) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameInprogressScreen(currentGame: activeGames.first),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameCreateScreen(),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                key: const Key('drawer-friends'),
                leading: const Icon(Icons.people, color: Colors.teal),
                title: const Text("Friends"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlayersScreen()),
                  );
                },
              ),
              ListTile(
                key: const Key('drawer-past-games'),
                leading: const Icon(Icons.history, color: Colors.teal),
                title: const Text("Past Games"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PastGamesScreen()),
                  );
                },
              ),
              ListTile(
                key: const Key('drawer-scheduled-games'),
                leading: const Icon(Icons.schedule, color: Colors.teal),
                title: const Text("Scheduled Games"),
                onTap: () {
                  Navigator.pop(context);
                  if (UserProvider().loggedInUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScheduledGamesScreen()),
                    );
                  }
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "ACTIVITY HUB",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  "Upcoming Games",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (topUpcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "No upcoming games scheduled",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...topUpcoming.map((game) => ListTile(
                      key: Key('drawer-upcoming-${game.id}'),
                      dense: true,
                      leading: const Icon(Icons.event, size: 18, color: Colors.orange),
                      title: Text(
                        game.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: Utilities.formatStartTime(game.scheduledTime),
                        builder: (context, snapshot) {
                          final timeText = snapshot.data ?? "Loading...";
                          return Text(
                            "${game.course.name} - $timeText",
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameStartScreen(unstartedGame: game),
                          ),
                        );
                      },
                    )),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  "Recent Games",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (topRecent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "No recent games played",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...topRecent.map((game) => ListTile(
                      key: Key('drawer-recent-${game.id}'),
                      dense: true,
                      leading: const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                      title: Text(
                        game.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: Utilities.formatStartTime(game.completedTime ?? game.scheduledTime),
                        builder: (context, snapshot) {
                          final timeText = snapshot.data ?? "Loading...";
                          return Text(
                            "${game.course.name} - $timeText",
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PastGameDetailsScreen(passedGame: game),
                          ),
                        );
                      },
                    )),
            ],
          );
        },
      ),
    );

    return list;
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
        future: _precacheFuture,
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
