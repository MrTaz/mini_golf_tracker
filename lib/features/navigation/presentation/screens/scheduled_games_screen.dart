import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/features/gameplay/data/models/game.dart';
import 'package:mini_golf_tracker/features/game_setup/presentation/screens/game_start_screen.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:intl/intl.dart';

class ScheduledGamesScreen extends StatefulWidget {
  const ScheduledGamesScreen({super.key});

  @override
  ScheduledGamesScreenState createState() => ScheduledGamesScreenState();
}

class ScheduledGamesScreenState extends State<ScheduledGamesScreen> {
  List<Game> scheduledGames = [];
  bool isLoading = true;
  bool _isOffline = false;

  @visibleForTesting
  void setOfflineForTesting(bool value) {
    setState(() {
      _isOffline = value;
    });
  }

  @visibleForTesting
  void clearScheduledGamesForTesting() {
    setState(() {
      scheduledGames.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadScheduledGames();
  }

  Future<void> _loadScheduledGames() async {
    setState(() {
      isLoading = true;
      _isOffline = false;
    });
    final user = UserProvider().loggedInUser;
    if (user != null) {
      try {
        final List<Game> dbGames = await Game.fetchGamesForCurrentUser(user.id);
        for (final game in dbGames) {
          await Game.saveLocalGame(game);
        }
      } catch (e) {
        _isOffline = true;
        Utilities.debugPrintWithCallerInfo(
            "Error fetching scheduled games: $e");
      }
    }
    final List<Game?> loadedGames =
        await Game.getLocallySavedGames(gameStatusTypes: ["unstarted_game"]);
    if (mounted) {
      setState(() {
        scheduledGames = loadedGames.whereType<Game>().toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scheduled Games'),
      ),
      body: Stack(
        children: [
          Utilities.backdropImageContinerWidget(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isOffline) _buildOfflineBanner(),
                      Expanded(
                        child: scheduledGames.isEmpty
                            ? Center(
                                child: Text(
                                  _isOffline
                                      ? "We couldn't sync your scheduled games. Please check your internet connection."
                                      : 'No scheduled games',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: scheduledGames.length,
                                itemBuilder: (context, index) {
                                  final game = scheduledGames[index];
                                  return Card(
                                    color: const Color.fromARGB(
                                        207, 255, 255, 255),
                                    surfaceTintColor: Colors.white,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.schedule,
                                        color: Colors.teal,
                                      ),
                                      title: Text(
                                        game.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Course: ${game.course.name}\nTime: ${DateFormat.yMMMMd().add_jm().format(game.scheduledTime)}',
                                      ),
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16.0),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GameStartScreen(
                                              unstartedGame: game,
                                            ),
                                          ),
                                        );
                                        _loadScheduledGames();
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              "Offline mode: showing cached scheduled games. Connect to the internet to sync.",
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
