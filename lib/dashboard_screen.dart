import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// import 'course.dart';
import 'create_game_screen.dart';
import 'game.dart';
import 'gravatar_image_view.dart';
import 'past_game_details_screen.dart';
import 'player.dart';
// import 'playergameinfo.dart';

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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const NewGameCard(),
                    const FriendsCard(),
                    PastGamesListView(),
                  ],
                ),
              ),
            )));
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

class FriendsCard extends StatefulWidget {
  const FriendsCard({super.key});

  @override
  FriendsCardState createState() => FriendsCardState();
}

class FriendsCardState extends State<FriendsCard> {
  final List<Player> playerFriends = [
    Player(
        id: 1,
        playerName: "Will",
        nickname: "Dad",
        totalScore: 50,
        email: "mrtaz28@gmail.com",
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 2,
        playerName: "Mandi",
        nickname: "Mom",
        totalScore: 62,
        email: "pumkey@gmail.com",
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 3,
        playerName: "Ava",
        nickname: "Aba",
        totalScore: 52,
        email: "princessavajayde@gmail.com",
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 4,
        playerName: "Brayden",
        nickname: "Monkey",
        totalScore: 51,
        email: "hunter15511@gmail.com",
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png"),
    Player(
        id: 5,
        playerName: "Collin",
        nickname: "Pumpkin",
        totalScore: 54,
        email: "pumkey41@gmail.com",
        avatarImageLocation: "assets/images/avatars_3d_avatar_28.png")
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            elevation: 6,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: <Widget>[
                  const ListTile(
                    title: Text('Friends'),
                  ),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal, child: Row(children: getPlayerFriends(context)))
                ]))));
  }

  List<Widget> getPlayerFriends(BuildContext context) {
    List<Widget> friendsColumns = [];
    playerFriends.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    for (var i = 0; i < playerFriends.length; i++) {
      var player = playerFriends[i];
      friendsColumns.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: getRankBorderColor(i), width: 2.0),
          color: Colors.white38,
          image: DecorationImage(
              alignment: const Alignment(0.8, 0.8), fit: BoxFit.none, scale: 3, image: getRankBackImg(i)),
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
        margin: const EdgeInsets.all(4),
        height: MediaQuery.of(context).size.height * 0.15,
        width: MediaQuery.of(context).size.width * 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
                child: CircleAvatar(
                    backgroundColor: Colors.teal, child: ClipOval(child: GravatarImageView(email: player.email!)))),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
                padding: const EdgeInsets.all(2.0),
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(player.nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        )))),
          ],
        ),
      ));
    }
    return friendsColumns;
  }

  Color getRankBorderColor(int currentRank) {
    switch (currentRank) {
      case 0:
        return const Color(0xFFDAA520);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFECC5C0);
      default:
        return const Color(0xffeeeeee);
    }
  }

  ImageProvider getRankBackImg(int currentRank) {
    switch (currentRank) {
      case 0:
        return Image.asset("assets/images/rank1.png").image;
      case 1:
        return Image.asset("assets/images/rank2.png").image;
      case 2:
        return Image.asset("assets/images/rank3.png").image;
      default:
        return Image.memory(kTransparentImage).image;
      // return Image.asset("assets/images/loggedin_background_2.png");
    }
  }
}

class PastGamesListView extends StatelessWidget {
  PastGamesListView({super.key});
  List<Game> previousGames = [];

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Card(
            elevation: 0,
            color: const Color.fromARGB(161, 255, 255, 255),
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  const ListTile(title: Text('Past games')),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      getGames(context),
                    ],
                  )
                ],
              ),
            )));
  }

  getGames(BuildContext context) {
    previousGames = [...Game.generateRandomGames(15)];
    if (previousGames.isNotEmpty) {
      return Expanded(
          child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: previousGames.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          debugPrint("Current Game: ${previousGames[index].course.id}");
          debugPrint("Current Game: ${previousGames[index].toJson()}");
          return InkWell(
              onTap: () => {
                    debugPrint("game tapped: $index"),
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return PastGameDetailsScreen(passedGame: previousGames[index]);
                    }))
                  },
              child: SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text(previousGames[index].course.name)]),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text(previousGames[index].startTime.toString())])
                    ],
                  )));
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ));
    } else {
      return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width * 0.9,
          child: const Align(alignment: Alignment.center, child: Text("Let's play!")));
    }
  }
}
