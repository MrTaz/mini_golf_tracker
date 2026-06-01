import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/app_drawer_widget.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/claim_account_screen.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
        title: 'Putt Scorer',
        theme: ThemeData(
          canvasColor: const Color(0xFFfafafa),
          fontFamily: 'Merriweather',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)
              .copyWith(secondary: const Color(0xFF009688)),
        ),
        home: const HomePage(),
        navigatorObservers: [routeObserver],
        initialRoute: '/',
        routes: {
          '/players': (context) {
            return const PlayersScreen();
          }
        });
  }
}

class HomePage extends StatefulWidget {
  final bool skipAutoResume;
  const HomePage({super.key, this.skipAutoResume = false});

  @override
  MainScaffold createState() => MainScaffold();
}

class MainScaffold extends State<HomePage> with RouteAware {
  MainScaffold();

  static bool skipPrecacheForTesting = false;

  Widget body = const HomeScreen();

  Future<List<void>>? _precacheFuture;
  int _drawerRefreshVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
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
    routeObserver.unsubscribe(this);
    UserProvider().removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  void didPopNext() {
    refreshDrawerState();
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
    } else if (UserProvider().pendingClaimPlayer != null) {
      body = const ClaimAccountScreen();
    } else {
      body = const HomeScreen();
    }
  }

  void _checkAndAutoResumeActiveGame() async {
    if (widget.skipAutoResume) return;
    final activeGames =
        await Game.getLocallySavedGames(gameStatusTypes: ['started']);
    if (activeGames.isNotEmpty) {
      activeGames.sort((a, b) => (b?.scheduledTime ?? DateTime(0)).compareTo(a?.scheduledTime ?? DateTime(0)));
      if (activeGames.first != null) {
        if (mounted && UserProvider().pendingClaimPlayer == null) {
          await Player.loadLocalGuestPlayers();
          setState(() {
            body = GameInprogressScreen(currentGame: activeGames.first!);
          });
        }
      }
    }
  }

  void changeBodyCallback(Widget nextPage) {
    if (mounted) {
      setState(() {
        body = nextPage;
        _drawerRefreshVersion++;
      });
    }
  }

  void refreshDrawerState() {
    if (mounted) {
      setState(() {
        _drawerRefreshVersion++;
      });
    }
  }

  void logout() async {
    await UserProvider().logout();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _precacheFuture,
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.connectionState != ConnectionState.waiting) {
            return Scaffold(
              key: const Key('home-page-scaffold'),
              appBar: AppBar(
                title: const Text('Putt Scorer'),
              ),
              drawer: AppDrawer(
                key: ValueKey(_drawerRefreshVersion),
                changeBodyCallback: changeBodyCallback,
                onLogout: logout,
                onRefreshRequested: refreshDrawerState,
                onTabSelected: (index) {
                  DashboardScreen.onTabSelect?.call(index);
                },
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
