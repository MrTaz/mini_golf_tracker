import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_create_screen.dart';
import 'package:mini_golf_tracker/game_inprogress_screen.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/login_screen.dart';
import 'package:mini_golf_tracker/past_game_details_screen.dart';
import 'package:mini_golf_tracker/past_games_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/player_avatar_widget.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/scheduled_games_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.changeBodyCallback,
    this.onLogout,
    this.onRefreshRequested,
  });

  final ValueChanged<Widget>? changeBodyCallback;
  final VoidCallback? onLogout;
  final VoidCallback? onRefreshRequested;

  void _showHome(BuildContext context) {
    Navigator.of(context).pop();
    changeBodyCallback?.call(const HomeScreen());
  }

  Future<void> _openLogin(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    onRefreshRequested?.call();
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
        currentAccountPicture: PlayerAvatarWidget(player: loggedInPlayer!),
        otherAccountsPictures: <Widget>[
          GestureDetector(
            onTap: onLogout,
            child: Semantics(
              label: 'Logout',
              child: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: FaIcon(FontAwesomeIcons.lock),
              ),
            ),
          )
        ],
      )
    ];
  }

  List<Widget> _buildDrawerList(BuildContext context) {
    final user = UserProvider().loggedInUser;
    final list = <Widget>[];
    if (user != null) {
      list.addAll(_buildUserAccounts(context));
    } else {
      list.add(
        UserAccountsDrawerHeader(
          accountName: const Text("Guest Profile"),
          accountEmail: null,
          currentAccountPicture: GestureDetector(
            onTap: () => _openLogin(context),
            child: PlayerAvatarWidget(
              player: Player.empty()
                ..nickname = 'Guest'
                ..ownerId = 'guest',
            ),
          ),
        ),
      );
      list.add(
        ListTile(
          leading: const Icon(Icons.home, color: Colors.teal),
          title: const Text("Home"),
          onTap: () => _showHome(context),
        ),
      );
      list.add(
        ListTile(
          leading: const Icon(Icons.login, color: Colors.teal),
          title: const Text("Sign In / Sign Up"),
          onTap: () => _openLogin(context),
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
          final nonNullGames = (snapshot.data ?? []).whereType<Game>().toList();
          final activeGames =
              nonNullGames.where((g) => g.status == 'started').toList();
          final hasActive = activeGames.isNotEmpty;

          final upcomingGames = nonNullGames
              .where((g) => g.status == 'unstarted_game')
              .toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
          final topUpcoming = upcomingGames.take(5).toList();

          final recentGames =
              nonNullGames.where((g) => g.status == 'completed').toList()
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
                title:
                    Text(hasActive ? "Resume Active Game" : "No current game"),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  if (hasActive) {
                    changeBodyCallback?.call(
                      GameInprogressScreen(currentGame: activeGames.first),
                    );
                  } else {
                    await navigator.push(
                      MaterialPageRoute(
                        builder: (context) => const GameCreateScreen(),
                      ),
                    );
                    onRefreshRequested?.call();
                  }
                },
              ),
              ListTile(
                key: const Key('drawer-friends'),
                leading: const Icon(Icons.people, color: Colors.teal),
                title: const Text("Friends"),
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator
                      .push(
                        MaterialPageRoute(
                            builder: (context) => const PlayersScreen()),
                      )
                      .then((_) => onRefreshRequested?.call());
                },
              ),
              const Divider(),
              ListTile(
                key: const Key('drawer-past-games'),
                leading: const Icon(Icons.history, color: Colors.teal),
                title: const Text("Past Games"),
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator
                      .push(
                        MaterialPageRoute(
                            builder: (context) => const PastGamesScreen()),
                      )
                      .then((_) => onRefreshRequested?.call());
                },
              ),
              if (topRecent.isNotEmpty)
                ...topRecent.map((game) => ListTile(
                      key: Key('drawer-recent-${game.id}'),
                      contentPadding:
                          const EdgeInsets.only(left: 40.0, right: 16.0),
                      dense: true,
                      leading: const Icon(Icons.emoji_events,
                          size: 18, color: Colors.amber),
                      title: Text(
                        game.course.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: Utilities.formatStartTime(
                            game.completedTime ?? game.scheduledTime),
                        builder: (context, snapshot) {
                          final timeText = snapshot.data ?? "Loading...";
                          int? score;
                          if (user != null) {
                            final playerInfo = game.players
                                .where((p) => p.playerId == user.id)
                                .firstOrNull;
                            score = playerInfo?.totalScore;
                          }
                          final scoreText = score != null && score > 0
                              ? " - Score: $score"
                              : "";
                          return Text(
                            "$timeText$scoreText",
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Save this history to the cloud.")),
                          );
                          navigator
                              .push(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              )
                              .then((_) => onRefreshRequested?.call());
                        } else {
                          navigator
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PastGameDetailsScreen(passedGame: game),
                                ),
                              )
                              .then((_) => onRefreshRequested?.call());
                        }
                      },
                    )),
              const Divider(),
              ListTile(
                key: const Key('drawer-scheduled-games'),
                leading: const Icon(Icons.schedule, color: Colors.teal),
                title: const Text("Scheduled Games"),
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  final route = user == null
                      ? MaterialPageRoute(
                          builder: (context) => const LoginScreen())
                      : MaterialPageRoute(
                          builder: (context) => const ScheduledGamesScreen());
                  navigator.push(route).then((_) => onRefreshRequested?.call());
                },
              ),
              if (user == null)
                ListTile(
                  key: const Key('drawer-locked-preview'),
                  contentPadding:
                      const EdgeInsets.only(left: 40.0, right: 16.0),
                  dense: true,
                  leading: const Icon(Icons.lock, size: 18, color: Colors.grey),
                  title: const Text(
                    "🔒 Sign up to schedule future rounds.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _openLogin(context),
                )
              else if (topUpcoming.isNotEmpty)
                ...topUpcoming.map((game) => ListTile(
                      key: Key('drawer-upcoming-${game.id}'),
                      contentPadding:
                          const EdgeInsets.only(left: 40.0, right: 16.0),
                      dense: true,
                      leading: const Icon(Icons.event,
                          size: 18, color: Colors.orange),
                      title: Text(
                        game.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: Utilities.formatStartTime(game.scheduledTime),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? "Loading...",
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    GameStartScreen(unstartedGame: game),
                              ),
                            )
                            .then((_) => onRefreshRequested?.call());
                      },
                    )),
            ],
          );
        },
      ),
    );

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: _buildDrawerList(context),
      ),
    );
  }
}
