import 'package:flutter/material.dart';
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
  final Player? loggedInUser = UserProvider().loggedInUser;
  late Widget body;
  int _selectedIndex = 0;

  final _pages = <Widget>[
    const HomeScreen(),
    const PlayersScreen(),
    const PastGamesScreen(),
    const CoursesScreen()
  ];
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
    Game.initializeLocalGames(loggedInUser!);
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
  bool isShowFriendsScreen = false;

  @override
  Widget build(BuildContext context) {
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
  }
}

// class NewGameCard extends StatelessWidget {
//   const NewGameCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: Card(
//             elevation: 6,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: <Widget>[
//                   const ListTile(
//                     title: Text('Create a new game'),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: <Widget>[
//                       FilledButton(
//                         // onPressed: () {/* ... */},
//                         onPressed: () {
//                           Navigator.of(context).push(MaterialPageRoute(builder: (context) {
//                             return const GameCreateScreen();
//                           }));
//                         },
//                         child: const Row(
//                           children: [
//                             Icon(
//                               Icons.add,
//                               size: 24.0,
//                             ),
//                             SizedBox(
//                               width: 5,
//                             ),
//                             Text('New Game'),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                     ],
//                   )
//                 ],
//               ),
//             )));
//   }
// }
