import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_card_widget.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/past_game_card_widget.dart';
import 'package:mini_golf_tracker/past_games_screen.dart';
import 'package:mini_golf_tracker/players_card_widget.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:mini_golf_tracker/player_avatar_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashboardScreen> {
  late Widget body;
  final _pages = <Widget>[
    const HomeScreen(),
    const PlayersScreen(),
    const PastGamesScreen(),
    const CoursesScreen()
  ];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateBody();
  }

  void _updateBody() {
    if (_selectedIndex == 0) {
      body = DashBoardLayout(
        updateBottomNavChangeNotifier: (bool value) {
          _onBottomNavigationButtonTapped(1);
        },
      );
    } else {
      body = _pages.elementAt(_selectedIndex);
    }
  }

  void _onBottomNavigationButtonTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _updateBody();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = UserProvider().loggedInUser;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      body: body,
      bottomNavigationBar: loggedInUser == null
          ? null
          : BottomNavigationBar(
              selectedItemColor: const Color(0xFF009688),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Friends',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: 'Past Games',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.golf_course),
                  label: 'Courses',
                )
              ],
              currentIndex: _selectedIndex,
              onTap: _onBottomNavigationButtonTapped,
            ),
    );
  }
}

class DashBoardLayout extends StatefulWidget {
  const DashBoardLayout(
      {super.key, required this.updateBottomNavChangeNotifier});

  final ValueChanged<bool> updateBottomNavChangeNotifier;

  @override
  State<DashBoardLayout> createState() => _DashBoardLayoutState();
}

class _DashBoardLayoutState extends State<DashBoardLayout> {
  bool isShowFriendsScreen = false;

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
    final loggedInUser = UserProvider().loggedInUser;

    if (loggedInUser == null) {
      return const Center(child: Text("Please log in"));
    }


    return FutureBuilder(
        future: Future.wait([
          Game.initializeLocalGames(loggedInUser),
        ]),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.connectionState != ConnectionState.waiting) {
            return isShowFriendsScreen
                ? const PlayersScreen()
                : Stack(children: [
                    Utilities.backdropImageContinerWidget(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(height: 10),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    PlayerAvatarWidget(
                                      player: loggedInUser,
                                      radius: 30,
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Hi, ${loggedInUser.nickname}!",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          loggedInUser.playerName,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const GameCardWidget(),
                            PlayersCard(onPlayerCardTap: (bool arg) {
                              setState(() {
                                isShowFriendsScreen = !isShowFriendsScreen;
                                widget.updateBottomNavChangeNotifier(
                                    isShowFriendsScreen);
                              });
                            }),
                            const PastGameCardWidget()
                          ],
                        ),
                      ),
                    ),
                  ]);
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
