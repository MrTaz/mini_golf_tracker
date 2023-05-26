import 'package:flutter/material.dart';

import 'game.dart';
import 'player.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                alignment: Alignment(1, 1),
                image: AssetImage("assets/images/loggedin_background_2.png"),
              ),
            ),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const NewGameCard(),
                    FriendsCard(),
                    GameHistoryCard(),
                  ],
                ),
              ),
            ))));
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
                    // subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FilledButton(
                        // onPressed: () {/* ... */},
                        onPressed: () => {},
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

class FriendsCard extends StatelessWidget {
  final List<Player> playerFriends = [
    Player(
        id: 1,
        playerName: "Will",
        nickname: "Dad",
        totalScore: 50,
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 2,
        playerName: "Mandi",
        nickname: "Mom",
        totalScore: 62,
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 3,
        playerName: "Ava",
        nickname: "Aba",
        totalScore: 52,
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 4,
        playerName: "Brayden",
        nickname: "Monkey",
        totalScore: 51,
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 5,
        playerName: "Collin",
        nickname: "Pumpkin",
        totalScore: 54,
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png")
  ];
  FriendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            elevation: 6,
            child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(children: <Widget>[
                  const ListTile(
                    title: Text('Friends'),
                  ),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: getPlayerFriends(context)))
                ]))));
  }

  List<Widget> getPlayerFriends(BuildContext context) {
    List<Widget> friendsColumns = [];
    playerFriends.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    for (var i = 0; i < playerFriends.length; i++) {
      var player = playerFriends[i];
      friendsColumns.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffeeeeee), width: 2.0),
          color: Colors.white38,
          image: DecorationImage(
              alignment: const Alignment(0.8, 0.8),
              fit: BoxFit.none,
              scale: 3,
              image: calculateRanking(i)),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          boxShadow: const [
            BoxShadow(
              color: Colors.white10,
              blurRadius: 4,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        height: MediaQuery.of(context).size.height * 0.15,
        width: MediaQuery.of(context).size.width * 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
                child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Image.asset(
                      player.avatarImageLocation ?? "",
                    ))),
            const SizedBox(
              height: 10.0,
            ),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(player.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      // color: flavorColor
                    ))),
          ],
        ),
      ));
    }
    return friendsColumns;
  }

  AssetImage calculateRanking(int currentRank) {
    switch (currentRank) {
      case 0:
        return const AssetImage("assets/images/rank1.png");
      case 1:
        return const AssetImage("assets/images/rank2.png");
      case 2:
        return const AssetImage("assets/images/rank3.png");
      default:
        return const AssetImage("assets/images/loggedin_background_2.png");
    }
  }
}

class GameHistoryCard extends StatelessWidget {
  GameHistoryCard({super.key});

  final List<Game> previousGames = [];

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            elevation: 0,
            color: Color.fromARGB(161, 255, 255, 255),
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  const ListTile(title: Text('Previous games')),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      getGames(previousGames),
                    ],
                  )
                ],
              ),
            )));
  }

  getGames(previousGames) {
    if (previousGames.length > 0) {
      return ListView.builder(
        itemCount: previousGames.length,
        prototypeItem: ListTile(
          title: Text(previousGames.first.course.name),
        ),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(previousGames[index].course.name),
          );
        },
      );
    } else {
      return const SizedBox(
          height: 600, width: 300, child: Center(child: Text("Let's play!")));
    }
  }
}
