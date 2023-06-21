import 'package:flutter/material.dart';

import 'create_game_screen.dart';
import 'home_screen.dart';
import 'past_games_list_view.dart';
import 'past_games_screen.dart';
import 'players_card_widget.dart';
import 'players_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashBoardScreenState createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashboardScreen> {
  Widget body = const DashBoardLayout();
  int _selectedIndex = 0;
  final _pages = <Widget>[
    const HomeScreen(),
    PlayersScreen(),
    const PastGamesScreen(),
  ];
  void _onBottomNavigationButtonTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        body = const DashBoardLayout();
      } else {
        body = _pages.elementAt(_selectedIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
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
          )
        ],
        currentIndex: _selectedIndex,
        onTap: _onBottomNavigationButtonTapped,
      ),
    );
  }
}

class DashBoardLayout extends StatelessWidget {
  const DashBoardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            alignment: Alignment(1, 1),
            image: AssetImage("assets/images/loggedin_background_2.png"),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const NewGameCard(),
                const PlayersCard(),
                PastGamesListView(),
              ],
            ),
          ),
        ));
  }
}

class NewGameCard extends StatelessWidget {
  const NewGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  const ListTile(
                    title: Text('Create a new game'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FilledButton(
                        // onPressed: () {/* ... */},
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                            return const CreateGameScreen();
                          }));
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 24.0,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text('New Game'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                ],
              ),
            )));
  }
}
