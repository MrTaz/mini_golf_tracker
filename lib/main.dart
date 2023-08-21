// import 'dart:js_interop';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mini_golf_tracker/asset_bouncy_animation.dart';
import 'package:mini_golf_tracker/asset_golf_ball_path.dart';
import 'package:mini_golf_tracker/assets.dart';
import 'package:mini_golf_tracker/dashboard_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/home_screen.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/players_screen.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mini_golf_tracker/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _formKey = GlobalKey<FormState>();

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  await DatabaseConnection.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Mini Golf Tracker',
        theme: ThemeData(
          primaryColor: const Color(0xFF009688),
          canvasColor: const Color(0xFFfafafa),
          fontFamily: 'Merriweather',
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(secondary: const Color(0xFF009688)),
        ),
        home: const HomePage(),
        initialRoute: '/',
        routes: {
          '/players': (context) {
            return const PlayersScreen();
          }
        });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  MainScaffold createState() => MainScaffold();
}

class MainScaffold extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Widget body = const HomeScreen();
  Player? loggedInPlayer;
  bool _userLoggedIn = false;
  // static late AssetImage backgroundImage;

  MainScaffold();

  void changeBodyCallback(Widget nextPage) {
    body = nextPage;
  }

  void isLoggedIn(bool loggedIn) {
    setState(() => _userLoggedIn = loggedIn);
  }

  Future<void> _initializeLoggedInPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    if (email == null) {
      logout();
    } else {
      try {
        String? loggedInUserJson = prefs.getString("loggedInUser");
        if (loggedInUserJson != null) {
          loggedInPlayer = Player.fromJson(jsonDecode(loggedInUserJson));
          if (loggedInPlayer != null) {
            UserProvider().loggedInUser = loggedInPlayer;
            final loadingUsers = await loggedInPlayer?.loadUserPlayers();
            isLoggedIn(true);
            changeProfileImage();
            body = const DashboardScreen();
          }
        }
      } catch (error) {
        Utilities.debugPrintWithCallerInfo("Error fetching logged-in player: $error");
        logout();
      }
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    setState(() {
      loggedInPlayer = null;
      isLoggedIn(false);
      body = const HomeScreen();
      final currentState = _scaffoldKey.currentState;
      if (currentState != null && currentState.isDrawerOpen) {
        _scaffoldKey.currentState!.openEndDrawer();
      }
    });
  }

  Image profileImage = Image.asset(
    "assets/images/avatars_3d_avatar_28.png",
    width: 120,
  );

  void changeProfileImage() async {
    setState(() {
      Future.microtask(() async {
        Utilities.debugPrintWithCallerInfo('Getting email for gravatar');
        SharedPreferences pref = await SharedPreferences.getInstance();
        String loggedInEmail = pref.getString("email") as String;
        if (loggedInEmail != "") {
          String gravatarImgUrl = Gravatar(loggedInEmail).imageUrl(size: 120);
          profileImage = Image.network(gravatarImgUrl);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // backgroundImage = const AppImage.backgroundMainScreens;
    _initializeLoggedInPlayer();
    // Future.microtask(() async {
    //   WidgetsFlutterBinding.ensureInitialized();
    //   final prefs = await SharedPreferences.getInstance();
    //   final email = prefs.getString("email");
    //   setState(() async {
    //     Utilities.debugPrintWithCallerInfo('Setting init state, $email');
    //     if (email == null) {
    //       logout();
    //     } else {
    //       loggedInPlayer = await Player.empty().getPlayerByEmail(email);
    //       isLoggedIn(true);
    //       changeProfileImage();
    //       body = const DashboardScreen();
    //     }
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.wait([
          precacheImage(AppImages.backgroundMainScreens, context),
        ]),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.connectionState != ConnectionState.waiting) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: const Text('Mini Golf Tracker'),
              ),
              drawer: Drawer(
                child: ListView(padding: const EdgeInsets.all(0), children: _buildDrawerList(context)),
              ),
              body: body,
            );
            ;
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    precacheImage(AppImages.backgroundMainScreens, context);
    super.didChangeDependencies();
  }

  List<Widget> _buildDrawerList(BuildContext context) {
    List<Widget> children = [];
    if (loggedInPlayer != null) {
      children.addAll(_buildUserAccounts(context));
    }
    return children;
  }

  List<Widget> _buildUserAccounts(BuildContext context) {
    return [
      UserAccountsDrawerHeader(
          accountName: Row(children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(loggedInPlayer?.playerName ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  loggedInPlayer?.nickname ?? "",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            )
          ]),
          accountEmail: Text(loggedInPlayer?.email ?? ""),
          currentAccountPicture: CircleAvatar(backgroundColor: Colors.teal, child: ClipOval(child: profileImage)),
          otherAccountsPictures: <Widget>[
            GestureDetector(
              onTap: () => logout(),
              child: Semantics(
                label: 'Logout',
                child: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(FontAwesomeIcons.lock),
                ),
              ),
            )
          ])
    ];
  }
}

// class _MyHomePageState extends State<MyHomePage> {
// final _pages = <Widget>[
//   const home(), //this is a stateful widget on a separate file
//   PlayersScreen(), //this is a stateful widget on a separate file
//   const GameStarted(),
// ];
// List<Player> players = [
//   Player(id: 1, playerName: "Will", nickname: "Dad"),
//   Player(id: 2, playerName: "Mandi", nickname: "Mom")
// ];
// List<Player> selectedPlayers = [];
// int _selectedIndex = 0;

// void _onBottomNavigationButtonTapped(int index) {
//   setState(() {
//     _selectedIndex = index;
//   });
// }

// @override
// Widget build(BuildContext context) {
//   return MainScaffold(
// appBar: AppBar(
//   title: const Text('Mini Golf Tracker'),
// ),
// body: android_large_3(
//     imageUrl: "assets/images/background.jpeg",
//     // "https://firebasestorage.googleapis.com/v0/b/flutterbricks-public.appspot.com/o/backgrounds%2Fcasey-horner-G2jAOMGGlPE-unsplash.jpg?alt=media&token=54d2effa-1220-4bc2-b03c-caed9feb22db",
//     child: Container()),
// body: _pages.elementAt(_selectedIndex),
// SingleChildScrollView(
//   child: Column(
//     children: <Widget>[
//       // Expanded(
//       // child:
//       ListView.builder(
//         shrinkWrap: true,
//         padding: const EdgeInsets.all(0.8),
//         itemCount: players.length,
//         itemBuilder: (BuildContext context, int index) {
//           return PlayerListItem(
//               key: Key('counter-${index}'), player: players[index]);
//         },
//       ),
//     ],
//   ),
// ),
// ]),
//   GridView.count(
//       crossAxisCount: 2,
//       mainAxisSpacing: 4.0,
//       crossAxisSpacing: 4.0,
//       padding: const EdgeInsets.all(0.0),
//       children: <Widget>[
//         GridView.count(
//           crossAxisCount: 2,
//           mainAxisSpacing: 4.0,
//           crossAxisSpacing: 4.0,
//           padding: const EdgeInsets.all(0.0),
//         ),
//         GridView.count(
//           crossAxisCount: 2,
//           mainAxisSpacing: 4.0,
//           crossAxisSpacing: 4.0,
//           padding: const EdgeInsets.all(0.0),
//         )
//       ])
// ]),
// bottomNavigationBar: BottomNavigationBar(
//   items: const [
//     BottomNavigationBarItem(
//       icon: Icon(Icons.home),
//       label: 'Home',
//     ),
//     BottomNavigationBarItem(
//       icon: Icon(Icons.people),
//       label: 'Players',
//     ),
//     BottomNavigationBarItem(
//       icon: Icon(Icons.folder),
//       label: 'Past Games',
//     )
//   ],
//   currentIndex: _selectedIndex,
//   onTap: _onBottomNavigationButtonTapped,
// ),
//         );
//   }
// }

// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   TextEditingController courseNameController = TextEditingController();
//   TextEditingController playerNameController = TextEditingController();
//   TextEditingController nicknameController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController phoneNumberController = TextEditingController();
//   String selectedCourseName = "";
//   List<String> courses = [];
//   List<Player> players = [];
//   List<Player> selectedPlayers = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchCourses().then((retrievedCourses) {
//       setState(() {
//         courses = retrievedCourses;
//       });
//     });
//     fetchPlayers();
//   }

//   @override
//   void dispose() {
//     courseNameController.dispose();
//     playerNameController.dispose();
//     nicknameController.dispose();
//     emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mini Golf Tracker'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Container(
//           height: 800, // Set a specific height as per your requirements
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const Text(
//                         'Create Game',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),
//                       DropdownButtonFormField<String>(
//                         value: selectedCourseName,
//                         onChanged: (newValue) {
//                           setState(() {
//                             selectedCourseName = newValue ?? '';
//                           });
//                         },
//                         items: courses
//                             .map<DropdownMenuItem<String>>((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(value),
//                           );
//                         }).toList(),
//                         decoration: const InputDecoration(
//                           labelText: 'Course Name',
//                         ),
//                       ),
//                       ElevatedButton(
//                         onPressed: () {
//                           if (_formKey.currentState?.validate() ?? false) {
//                             // All form fields are valid. Proceed with game creation.
//                             createGame(selectedCourseName, selectedPlayers);
//                           }
//                         },
//                         child: const Text('Start Game'),
//                       ),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Course Name',
//                         ),
//                         controller: courseNameController,
//                       ),
//                       const SizedBox(height: 16.0),
//                       ElevatedButton(
//                         onPressed: () {
//                           String courseName = courseNameController.text;
//                           saveCourse(courseName);
//                         },
//                         child: const Text('Create Game'),
//                       ),
//                       const SizedBox(height: 32.0),
//                       const Text(
//                         'Add Players',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: players.length,
//                           itemBuilder: (BuildContext context, int index) {
//                             Player player = players[index];
//                             bool isSelected = selectedPlayers.contains(player);

//                             return ListTile(
//                               title: Text(player.playerName),
//                               subtitle: Text(player.nickname),
//                               trailing: IconButton(
//                                 icon: Icon(isSelected
//                                     ? Icons.check_box
//                                     : Icons.check_box_outline_blank),
//                                 onPressed: () {
//                                   if (isSelected) {
//                                     removePlayerFromGame(player);
//                                   } else {
//                                     addPlayerToGame(player);
//                                   }
//                                 },
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 16.0),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Player Name',
//                         ),
//                         controller: playerNameController,
//                         validator: (value) {
//                           if (value?.isEmpty ?? true) {
//                             return 'Please enter a player name.';
//                           }
//                           return null; // Return null if the value is valid.
//                         },
//                         // Error message display
//                         autovalidateMode: AutovalidateMode.onUserInteraction,
//                       ),
//                       const SizedBox(height: 16.0),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Nickname/Handle',
//                         ),
//                         controller: nicknameController,
//                       ),
//                       const SizedBox(height: 16.0),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Email',
//                         ),
//                         controller: emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value?.isNotEmpty == true &&
//                               !_isValidEmail(value!)) {
//                             return 'Please enter a valid email or leave it blank.';
//                           }
//                           return null; // Return null if the value is valid.
//                         },
//                         // Error message display
//                         autovalidateMode: AutovalidateMode.onUserInteraction,
//                       ),
//                       const SizedBox(height: 16.0),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Mobile Phone',
//                         ),
//                         controller: phoneNumberController,
//                         keyboardType: TextInputType.phone,
//                         validator: (value) {
//                           if (value?.isNotEmpty == true &&
//                               !_isValidPhoneNumber(value!)) {
//                             return 'Please enter a valid phone number or leave it blank.';
//                           }
//                           return null; // Return null if the value is valid.
//                         },
//                         // Error message display
//                         autovalidateMode: AutovalidateMode.onUserInteraction,
//                       ),
//                       const SizedBox(height: 16.0),
//                       ElevatedButton(
//                         onPressed: () {
//                           if (_formKey.currentState?.validate() ?? false) {
//                             // All form fields are valid. Proceed with saving the player.
//                             submitPlayerForm();
//                           }
//                         },
//                         child: const Text('Save Player'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     // Regular expression pattern to validate email format.
//     final emailRegex = RegExp(
//         r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
//     return emailRegex.hasMatch(email);
//   }

//   bool _isValidPhoneNumber(String phoneNumber) {
//     // Implement your validation logic for phone number here.
//     // You can use a regular expression pattern or any other validation logic.
//     // Return true if the phone number is valid, false otherwise.
//     // Example using a simple pattern: Accepts only numbers and optional dashes or spaces.
//     final phoneRegex = RegExp(r'^[0-9- ]*$');
//     return phoneRegex.hasMatch(phoneNumber);
//   }

//   void saveCourse(String courseName) async {
//     // Save the course to the database
//     final response =
//         await supabase.from('courses').insert({'name': courseName}).execute();

//     if (response.error != null) {
//       // Handle error if any
//       if (kDebugMode) {
//         print('Error saving course: ${response.error?.message}');
//       }
//       throw DatabaseConnectionError(
//           'Failed to save courses: ${response.error?.message}');
//     } else {
//       // Course saved successfully
//       if (kDebugMode) {
//         print('Course saved successfully');
//       }
//     }
//   }

//   void submitPlayerForm() {
//     // Get player information from the form
//     String playerName = playerNameController.text;
//     String nickname = nicknameController.text;
//     String email = emailController.text;
//     String phoneNumber = phoneNumberController.text;

//     // Save the player information to the database
//     savePlayer(playerName, nickname, email, phoneNumber);
//   }

//   void savePlayer(String playerName, String nickname, String email, String phoneNumber) async {
//     final response = await supabase.from('players').insert([
//       {
//         'player_name': playerName,
//         'nickname': nickname,
//         'email': email,
//         'phone_number': phoneNumber,
//       }
//     ]).execute();

//     if (response.error != null) {
//       // Handle error if any
//       if (kDebugMode) {
//         print('Error saving player: ${response.error?.message}');
//       }
//       throw DatabaseConnectionError(
//           'Failed to save player: ${response.error?.message}');
//     } else {
//       // Player saved successfully
//       if (kDebugMode) {
//         print('Player saved successfully');
//       }
//     }
//   }

//   void fetchPlayers() async {
//     final response = await supabase.from('players').select().execute();

//     if (response.error != null) {
//       // Handle error if any
//       if (kDebugMode) {
//         print('Error fetching players: ${response.error?.message}');
//       }
//       throw DatabaseConnectionError(
//           'Failed to fetch players: ${response.error?.message}');
//     } else {
//       // Players fetched successfully
//       final List<dynamic>? data = response.data;
//       if (data != null) {
//         players = data.map((item) => Player.fromJson(item)).toList();
//         setState(() {}); // Trigger a UI update to reflect the fetched players
//       }
//     }
//   }

//   void addPlayerToGame(Player player) {
//     if (selectedPlayers.length < 6) {
//       setState(() {
//         selectedPlayers.add(player);
//       });
//     }
//   }

//   void removePlayerFromGame(Player player) {
//     setState(() {
//       selectedPlayers.remove(player);
//     });
//   }

//   void createGame(String selectedCourseName, List<Player> selectedPlayers) async {
//     try {
//       // Step 1: Fetch Course Details
//       final courseDetails = await fetchCourseDetails(selectedCourseName);

//       // Step 2: Calculate Par for Holes (Optional)
//       final parStrokes = calculateParStrokes(courseDetails);

//       // Step 3: Add Players to the Game
//       List<PlayerGameInfo> gamePlayers = [];
//       for (Player player in selectedPlayers) {
//         final playerGameInfo = PlayerGameInfo(
//             playerId: player.id, playerName: player.playerName, scores: []);
//         gamePlayers.add(playerGameInfo);
//       }

//       // Step 4: Create a New Game
//       final game = Game(
//           course: courseDetails,
//           players: gamePlayers,
//           startTime: DateTime.now());

//       // Step 5: Save Game to Database
//       await saveGameToDatabase(game);

//       // Step 6: Display Success Message or Perform Further Actions
//       displaySuccessMessage();
//       // Navigate to a different screen or update the UI as needed
//       navigateToScreen();
//     } catch (e) {
//       // Handle any errors that occurred during the process
//       handleError(e);
//     }
//   }

//   Map<int, int> calculateParStrokes(Course courseDetails) {
//     final parStrokes = <int, int>{};

//     // Perform any necessary calculations or logic to determine the par strokes for each hole
//     // For example, you could have a formula or predefined values to calculate par strokes

//     // Here's an example of setting par strokes based on a fixed value of 3 for each hole
//     for (int holeNumber = 1;
//         holeNumber <= courseDetails.numberOfHoles;
//         holeNumber++) {
//       parStrokes[holeNumber] = 3;
//     }

//     return parStrokes;
//   }

//   void displaySuccessMessage() {
//     const snackBar = SnackBar(content: Text('Game saved successfully'));
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   void navigateToScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const GameStarted()),
//     );
//   }

//   void handleError(dynamic error) {
//     // Handle specific types of errors differently, if needed
//     if (error is DatabaseConnectionError) {
//       // Handle database connection errors
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Connection Error'),
//             content: Text(error.message),
//             actions: [
//               TextButton(
//                 child: const Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     } else {
//       // Handle generic errors
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Error'),
//             content: const Text(
//                 'An error occurred during the game creation process.'),
//             actions: [
//               TextButton(
//                 child: const Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
// }
