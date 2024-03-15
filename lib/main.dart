import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testt/pages/quiz_play.dart';
import 'package:testt/pages/welcome.dart';
import 'package:testt/popup.dart';
import 'package:testt/services/database.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:testt/ThemeProvider.dart';
import 'package:testt/google_signin_api.dart';
import 'package:testt/my_drawer_header.dart';
import 'package:testt/pages/Contact.dart';
import 'package:testt/pages/about.dart';
import 'package:testt/pages/calculator.dart';
import 'package:testt/pages/gallery.dart';
import 'package:testt/pages/settings.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initNotifications();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyWelcomeApp(),
    ),
  );
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('classme');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (String? payload) async {
      // Handle notification tap
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: themeProvider.currentTheme,
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int myIndex = 0;
  bool isOnline = false;
  bool isBluetoothEnabled = false;

  late Timer refreshTimer;
  bool showStatusIndicators = true;

  // late Stream quizStream; // Declare the stream variable as late
  late Stream<QuerySnapshot<Map<String, dynamic>>>
      quizStream; // Specify the correct type
  late DatabaseService databaseService; // Declare the database service

  Widget quizList() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: StreamBuilder(
          stream: quizStream,
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Display a loader while data is being fetched
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return snapshot.data == null
                ? Container()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemExtent: 180,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 16.0),
                            child: QuizTile(
                              noOfQuestions: snapshot.data!.docs.length,
                              imageUrl: snapshot.data!.docs[index]
                                  .data()['quizImgUrl'],
                              title: snapshot.data!.docs[index]
                                  .data()['quizTitle'],
                              description:
                                  snapshot.data!.docs[index].data()['quizDesc'],
                              id: snapshot.data!.docs[index].id,
                            ),
                          ),
                          Divider(
                            color: Theme.of(context).primaryColor,
                            thickness: 2.0,
                            height: 2,
                          ),
                        ],
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    // Initialize the database service with a unique ID
    databaseService = DatabaseService(uid: Uuid().v4());

    // Initialize quizStream with an empty stream
    quizStream = Stream.empty();

    // Load quiz data into quizStream
    databaseService.getQuizData2().then((value) {
      setState(() {
        quizStream = value;
      });
    });
    super.initState();

    // Check for internet connectivity
    checkInternetConnectivity().then((result) {
      setState(() {
        isOnline = result;
      });
    });

    // Check for Bluetooth status
    checkBluetoothStatus().then((value) {
      setState(() {
        isBluetoothEnabled = value;
      });
    });

    // Set up periodic timer for refreshing every 1 minute
    refreshTimer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      refreshStatus();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    refreshTimer.cancel();
    super.dispose();
  }

  void refreshStatus() {
    // Check and update the status of internet connectivity and Bluetooth
    checkInternetConnectivity().then((result) {
      setState(() {
        isOnline = result;
      });
    });

    checkBluetoothStatus().then((value) {
      setState(() {
        isBluetoothEnabled = value;
      });
    });
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> checkBluetoothStatus() async {
    try {
      FlutterBlue flutterBlue = FlutterBlue.instance;

      // Create a Completer to handle the async operation
      Completer<bool> completer = Completer<bool>();

      // Initialize the subscription variable
      late StreamSubscription<BluetoothState> subscription;

      // Listen to the first event emitted by the Bluetooth state stream
      subscription = flutterBlue.state.listen((BluetoothState bluetoothState) {
        // Check the Bluetooth state and complete the Future
        completer.complete(bluetoothState == BluetoothState.on);

        // Cancel the subscription after the first event
        subscription.cancel();
      });

      return await completer.future; // Wait for the Future to complete
    } catch (e, stackTrace) {
      print('Error in checkBluetoothStatus: $e\n$stackTrace');
      return false;
    }
  }

  void _onItemTapped(int index) {
    // Handle navigation to different pages based on index
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CalculatorPage()),
        );
        break;
    }
  }

  Widget MyDrawerList() {
    return Container(
      padding: EdgeInsets.only(top: 15),
      child: Column(
        // list of menu items
        children: [
          menuItem(Icons.home, "Home"),
          menuItem(Icons.calculate, "Calculator"),
          menuItem(Icons.account_circle, "About"),
          menuItem(Icons.contact_phone_rounded, "Contact"),
          menuItem(Icons.image_rounded, "Gallery"),
          SizedBox(height: 200),
          menuItem(Icons.settings_applications_sharp, "Settings"),
          menuItem(Icons.login, "LogOut"),
          // Add more menu items as needed
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title) {
    return Material(
      child: InkWell(
        onTap: () {
          _onMenuItemSelected(title);
        },
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Icon(icon, size: 20, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenuItemSelected(String title) {
    switch (title) {
      case "Home":
        break;
      case "Calculator":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CalculatorPage()),
        );
        break;
      case "About":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutPage()),
        );
        break;
      case "Contact":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ContactPage()),
        );
        break;
      case "Gallery":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PickImage()),
        );
        break;
      case "Settings":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
      case "LogOut":
        logout();
        break;
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignInApi.logout();
      FirebaseAuth.instance.signOut();

// Navigate to the login page and replace the current screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyWelcomeApp()),
      );
      // Show a success message
      showPopup(context, 'Success', 'Successfully Logged Out!');
    } catch (e) {
      print('Error logging out: $e');

      // Show an error message
      showPopup(context, 'Error', 'Failed to log out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final showStatusIndicators = themeProvider.showStatusIndicators;
    bool isFABVisible = true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.primaryColor,
        actions: [
          if (showStatusIndicators)
            Row(
              children: [
                ToggleThemeButton(), // Add the theme toggle button to the AppBar
                if (isOnline)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.wifi,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (!isOnline)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (isBluetoothEnabled)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.bluetooth, color: Colors.white, size: 20),
                  ),
                if (!isBluetoothEnabled)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.bluetooth_disabled,
                        color: Colors.white, size: 20),
                  ),
              ],
            ),
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                themeProvider.showStatusIndicators = !showStatusIndicators;
              });

              // Show a text notification
              if (showStatusIndicators) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Icons are now visible'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Icons are now hidden'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          // Toggle the visibility of FloatingActionButton on screen tap
          setState(() {
            isFABVisible = !isFABVisible;
          });
        },
        child: quizList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            themeProvider.currentTheme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: themeProvider
            .currentTheme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: themeProvider
            .currentTheme.bottomNavigationBarTheme.unselectedItemColor,
        onTap: _onItemTapped,
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calculate), label: 'Calculate'),
        ],
      ),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                MyHeaderDrawer(),
                MyDrawerList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToggleThemeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return IconButton(
      icon: Icon(
        Icons.palette,
        size: 20,
      ),
      color: Colors.white,
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}

class QuizTile extends StatelessWidget {
  final String? imageUrl, title, id, description;
  final int noOfQuestions;

  QuizTile({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.id,
    required this.noOfQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Get the current user ID
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        // Check if the user ID is not null
        if (userId != null) {
          // Get the current date and time in ISO 8601 format
          String currentDate = DateTime.now().toIso8601String();

          // Create a new quiz result document ID
          String resultId = Uuid().v4();

          // Create a reference to the Firestore instance
          FirebaseFirestore firestore = FirebaseFirestore.instance;

          try {
            // Add the quiz result to the quizResults collection
            await firestore.collection('quizResults').doc(resultId).set({
              'userID': userId, // Reference to user document
              'quizID': id, // Reference to quiz document
              'score': 0, // Initialize score as 0
              'status': 'in progress', // Quiz status (completed or in progress)
              'dateCompleted': null, // Date and time when the quiz was completed
            });

            // Navigate to the quiz play page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizPlay(id ?? ""),
              ),
            );
          } catch (error) {
            print('Error recording quiz result: $error');
            // Handle error
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                imageUrl ?? "", // Use a default value if imageUrl is null
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
              Container(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title ?? "", // Use a default value if title is null
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        description ??
                            "", // Use a default value if description is null
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}