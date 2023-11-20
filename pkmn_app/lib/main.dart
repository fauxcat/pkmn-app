import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pkmn_app/pokemon.dart';
import 'package:provider/provider.dart';
import 'dart:math';

late Box<Pokemon> box;

Future<void> main() async {
  await initApp();
  runApp(MyApp());
}

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PokemonAdapter());
  box = await Hive.openBox<Pokemon>('pokedex');

  await loadPokemonData();
}

Future<void> loadPokemonData() async {
  try {
    String csv = "assets/pokemon_list.csv";
    String fileData = await rootBundle.loadString(csv);

    List<String> rows = fileData.split("\n");

    for (int i = 1; i < rows.length; i++) {
      String row = rows[i];
      List<String> itemInRow = row.split(",");

      Pokemon pokemon = Pokemon(
        number: int.parse(itemInRow[0]),
        name: itemInRow[1],
        type1: itemInRow[2],
        type2: itemInRow[3],
        hp: int.parse(itemInRow[4]),
        attack: int.parse(itemInRow[5]),
        defense: int.parse(itemInRow[6]),
        spAttack: int.parse(itemInRow[7]),
        spDefense: int.parse(itemInRow[8]),
        speed: int.parse(itemInRow[9]),
        found: false, // All Pokemon are initially not found
      );

      int key = int.parse(itemInRow[0]);
      box.put(key, pokemon);
    }
  } catch (e) {
    print("Error loading Pokemon data: $e");
    // Could implement visual error message for user here. Restart program
  }
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
        home: MyNavBar(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var barColor = Color.fromARGB(255, 242, 29, 29);
  int selectedPokedexEntryIndex = 0;
  int location = 1;
  int selectedWildIndex = -1;
  Pokemon? selectedPokemon;

  void updateFound(int index, int found) async {
    final pokemon = box.getAt(index);
    if (pokemon != null) {
      pokemon.found = true;
      await box.putAt(index, pokemon);
      print("Pokemon ${pokemon.name} at index $index found: ${pokemon.found}");
      notifyListeners();
    }
  }

  void selectPokedexEntry(int index) {
    selectedPokedexEntryIndex = index;
    notifyListeners();
  }

  List<Pokemon?> getPokemonForLocation(int location) {
    List<Pokemon?> pokemonList = box.values.toList();

    // Define the number of locations and calculate Pokemon per location
    int numberOfLocations = 7; // Change this based on your requirements
    int pokemonPerLocation = (pokemonList.length / numberOfLocations).ceil();

    // Determine the range of Pokemon indices accessible for the current location
    int startIndex = (location - 1) * pokemonPerLocation;
    int endIndex = startIndex + pokemonPerLocation;

    // Filter Pokemon list to show only the subset for the current location
    return pokemonList.sublist(startIndex,
        endIndex > pokemonList.length ? pokemonList.length : endIndex);
  }

  void updateLocation(int newLocation) {
    location = newLocation;
    selectedPokemon = null;
    notifyListeners();
  }

  void selectRandomPokemon(int location) {
    List<Pokemon?> availablePokemon = getPokemonForLocation(location);

    if (availablePokemon.isNotEmpty) {
      // Generate a random index within the available Pokemon range
      int randomIndex = Random().nextInt(availablePokemon.length);
      selectedPokemon = availablePokemon[randomIndex];
      selectedWildIndex = box.keys.toList().indexOf(selectedPokemon?.number);
      notifyListeners();
    }
  }
}

class MyNavBar extends StatefulWidget {
  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  var selectedPageIndex = 0;
  var pageTitle = "";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    Widget page;
    switch (selectedPageIndex) {
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
        throw UnimplementedError('no widget for $selectedPageIndex');
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
              currentIndex: selectedPageIndex,
              iconSize: 30,
              selectedFontSize: 20,
              unselectedFontSize: 15,
              onTap: (value) {
                setState(() {
                  selectedPageIndex = value;
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
    var location = appState.location;

    return Scaffold(
      appBar: AppBar(
        title: Text("Catch Them All!"),
        titleTextStyle: TextStyle(fontSize: 30),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (appState.selectedPokemon != null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/sprites/${appState.selectedPokemon!.number}.gif',
                    height: 400, // Adjust height as needed
                    width: 400, // Adjust width as needed
                  ),
                  SizedBox(height: 20),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "There's nothing here yet...",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 20.0),
            child: Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade900,
                ),
                onPressed: () {
                  final double catchChance = 1;
                  if (Random().nextDouble() > 1 - catchChance) {
                    // If caught successfully
                    appState.updateFound(appState.selectedWildIndex, 1);
                  } else {
                    print("Not caught");
                  }
                  appState.selectRandomPokemon(location);
                },
                child: Text(
                  'Throw a Pokeball!',
                  style: TextStyle(color: Colors.red.shade500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // This will be the map page - https://mapstyle.withgoogle.com/

  void updateLocation(int newLocation) =>
      context.read<MyAppState>().updateLocation(newLocation);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Map"),
        titleTextStyle: TextStyle(fontSize: 30),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: Center(
        child: Stack(
          children: [
            // Add map image as a background - Ask Nad about this, not sure what to do with resizing changing button place and image quality

            Image.asset(
              'assets/campusMap2.jpg',
              width: 1024,
              height: 1024,
              fit: BoxFit.contain,
            ),

            //Overlay buttons on the map
            Positioned(
              top: 200,
              left: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle button click
                      // Change values/location in appState here
                      updateLocation(1);
                      print("Button 1");
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Colors.white,
                    ),
                    child: Icon(Icons.pin_drop),
                  ),
                  SizedBox(height: 3.0),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 1.0, horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      border: Border.all(color: primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Button 1',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle button click
                      // Change values/location in appState here
                      updateLocation(2);
                      print("Button 2");
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                    ),
                    child: Icon(Icons.pin_drop),
                  ),
                  SizedBox(height: 3.0),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 1.0, horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      border: Border.all(color: primaryColor),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Button 2',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PokedexPage extends StatefulWidget {
  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  // This will be the pokedex page - Gridview with buttons for each pokemon...
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pokedex"),
        titleTextStyle: TextStyle(fontSize: 30),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: GridView.count(
        crossAxisCount: 3,
        children: List.generate(151, (index) {
          final pokemon = box.getAt(index);
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
                    appState.selectPokedexEntry(index);
                    _showBottomSheet(
                        context, index, appState.selectedPokedexEntryIndex);
                  },
                  child: LayoutBuilder(builder: (context, constraints) {
                    double imageSize = constraints.maxWidth * 0.9;
                    return Column(
                      children: [
                        Image.asset(
                          'assets/sprites/${index + 1}.gif',
                          height: imageSize,
                          width: imageSize,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '${pokemon?.name ?? ""}',
                          ),
                        ),
                      ],
                    );
                  })),
            ),
          );
        }),
      ),
    );
  }

  void _showBottomSheet(
      BuildContext context, int index, int selectedPokedexEntryIndex) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Color.fromARGB(255, 16, 21, 25),
        builder: (BuildContext context) {
          final pokemon = box.getAt(selectedPokedexEntryIndex);
          return Container(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pokemon?.name ?? ""}',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Type 1: ${pokemon?.type1 ?? ""}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Type 2: ${pokemon?.type2 ?? ""}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'HP: ${pokemon?.hp ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Attack: ${pokemon?.attack ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Defense: ${pokemon?.defense ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Sp. Attack: ${pokemon?.spAttack ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Sp. Defense: ${pokemon?.spDefense ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Speed: ${pokemon?.speed ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Found = ${pokemon?.found ?? 0}',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Other info...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
