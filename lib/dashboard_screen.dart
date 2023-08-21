import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/courses_screen.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_card_widget.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/past_game_card_widget.dart';
import 'package:mini_golf_tracker/past_games_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_card_widget.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashboardScreen> {
  late Widget body;
  int _selectedIndex = 0;

  final _pages = <Widget>[const HomeScreen(), const PlayersScreen(), const PastGamesScreen(), const CoursesScreen()];
  void _onBottomNavigationButtonTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        body = DashBoardLayout(
          updateBottomNavChangeNotifier: (bool value) {
            _onBottomNavigationButtonTapped(1);
          },
        );
      } else {
        body = _pages.elementAt(_selectedIndex);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    body = DashBoardLayout(
      updateBottomNavChangeNotifier: (bool value) {
        _onBottomNavigationButtonTapped(1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF009688),
        unselectedItemColor: Colors.grey,
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
  final ValueChanged<bool> updateBottomNavChangeNotifier;

  const DashBoardLayout({Key? key, required this.updateBottomNavChangeNotifier}) : super(key: key);

  @override
  State<DashBoardLayout> createState() => _DashBoardLayoutState();
}

class _DashBoardLayoutState extends State<DashBoardLayout> {
  final Player? loggedInUser = UserProvider().loggedInUser;
  bool isShowFriendsScreen = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          Game.initializeLocalGames(loggedInUser!),
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
                            const GameCardWidget(),
                            PlayersCard(onPlayerCardTap: (bool arg) {
                              setState(() {
                                isShowFriendsScreen = !isShowFriendsScreen;
                                widget.updateBottomNavChangeNotifier(isShowFriendsScreen);
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
                    child: CustomPaint(painter: GolfBallPainter(), child: const SizedBox(width: 100, height: 100))),
              ),
            );
          }
        });
  }
}
