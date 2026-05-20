import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/game.dart';
import 'package:mini_golf_tracker/game_start_screen.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:intl/intl.dart';

class ScheduledGamesScreen extends StatefulWidget {
  const ScheduledGamesScreen({super.key});

  @override
  ScheduledGamesScreenState createState() => ScheduledGamesScreenState();
}

class ScheduledGamesScreenState extends State<ScheduledGamesScreen> {
  List<Game> scheduledGames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledGames();
  }

  Future<void> _loadScheduledGames() async {
    setState(() {
      isLoading = true;
    });
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
              : scheduledGames.isEmpty
                  ? const Center(
                      child: Text(
                        'No scheduled games',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: scheduledGames.length,
                        itemBuilder: (context, index) {
                          final game = scheduledGames[index];
                          return Card(
                            color: const Color.fromARGB(207, 255, 255, 255),
                            surfaceTintColor: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameStartScreen(
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
    );
  }
}
