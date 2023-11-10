import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'PKMN App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 242, 29, 29)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var barColor = Color.fromARGB(255, 242, 29, 29);

  /*
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[]; //List that can only store WordPair objects

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
  */
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  var pageTitle = "";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = MainPage();
        break;
      case 1:
        page = MapPage();
        break;
      case 2:
        page = PokedexPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: page,
            ),
          ),
          SafeArea(
            child: BottomNavigationBar(
              //Replace with navigationBar and adjust as needed
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.catching_pokemon_sharp),
                  label: ('Home'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: ('Map'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: ('Pokedex'),
                ),
              ],
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .secondary, // Customize the unselected label text color
              backgroundColor: primaryColor, // Custom
              fixedColor: Colors.white,
              currentIndex: selectedIndex,
              iconSize: 30,
              selectedFontSize: 20,
              unselectedFontSize: 15,
              onTap: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  // This will be the main page
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Main/Home/Location"),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: Center(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 20.0),
            child: Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade900,
                ),
                onPressed: () {
                  // Do next action - depends on current situation
                },
                child: Text('Action Button',
                    style: TextStyle(color: Colors.red.shade500)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapPage extends StatelessWidget {
  // This will be the map page - https://mapstyle.withgoogle.com/
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Map"),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Add map image as a background - Ask Nad about this, not sure what to do with resizing changing button place and image quality
          Center(
            child: Image.asset(
              'assets/campusMap2.jpg',
              width: 1024,
              height: 1024,
              fit: BoxFit.fill,
            ),
          ),
          //Overlay buttons on the map
          Positioned(
            top: 0,
            left: 0,
            child: ElevatedButton(
              onPressed: () {
                // Handle button click
                // Change values/location in appState here
                print("Button 1");
              },
              child: Text('Button 1'),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Handle button click
                // Change values/location in appState here
                print("Button 2");
              },
              child: Text('Button 2'),
            ),
          ),
        ],
      ),
    );
  }
}

class PokedexPage extends StatelessWidget {
  // This will be the pokedex page - Gridview with buttons for each pokemon...
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pokedex"),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: GridView.count(
        crossAxisCount: 3,
        children: List.generate(151, (index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: MaterialButton(
                minWidth: double.infinity,
                height: double.infinity,
                color: Color.fromARGB(255, 10, 15, 19),
                textColor: Colors.white,
                onPressed: () {
                  // Handle button click (open pop-up with pkmn info)
                  _showBottomSheet(context, index);
                },
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Item $index',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, int index) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Color.fromARGB(255, 16, 21, 25),
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                  'Button $index pressed\nThis is where I keep the type, name and other info about the pokemon',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        });
  }
}


/*
class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel:
              "${pair.first} ${pair.second}", //pair.asPascalCase would also work
        ),
      ),
    );
  }
}
*/