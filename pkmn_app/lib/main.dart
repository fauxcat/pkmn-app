import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pkmn_app/pokemon.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';

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
    print("Error loading Pokémon data: $e");
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
  int pokeballCount = 10000;
  Pokemon? selectedPokemon;

  void updateFound(int index, int found) async {
    final pokemon = box.getAt(index);
    if (pokemon != null) {
      pokemon.found = true;
      await box.putAt(index, pokemon);
      print("Pokémon ${pokemon.name} at index $index found: ${pokemon.found}");
      notifyListeners();
    }
  }

  void selectPokedexEntry(int index) {
    selectedPokedexEntryIndex = index;
    notifyListeners();
  }

  List<Pokemon?> getPokemonForLocation(int location) {
    List<Pokemon?> pokemonList = box.values.toList();
    int numberOfLocations = 7; // Change this based on your requirements

    List<Pokemon?> pokemonForLocation = [];
    int currentIndex = location - 1;

    // Iterate through the list to select the corresponding Pokemon for the location
    while (currentIndex < pokemonList.length) {
      pokemonForLocation.add(pokemonList[currentIndex]);
      currentIndex += numberOfLocations;
    }

    return pokemonForLocation;
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

enum EncounterType {
  FindEncounter,
  CatchPokemon,
  SpinPokestop,
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _showCaughtText = false;
  String _caughtMessage = '';
  EncounterType _currentEncounter = EncounterType.FindEncounter;

  void _showCaughtMessage(bool isCaught) {
    if (mounted) {
      setState(() {
        _showCaughtText = true;
        _caughtMessage =
            isCaught ? 'Nice! You caught it!' : 'Oh no! The Pokémon ran away!';
      });

      // After 5 seconds, hide the text
      Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showCaughtText = false;
          });
        }
      });
    }
  }

  Widget _buildThrowPokeballButton(BuildContext context) {
    var appState = Provider.of<MyAppState>(context, listen: false);

    String buttonText = '';
    if (_currentEncounter == EncounterType.CatchPokemon) {
      buttonText = 'Catch a Pokémon!';
    } else if (_currentEncounter == EncounterType.FindEncounter) {
      buttonText = 'Find an Encounter!';
    } else {
      // Add other encounter types here (e.g., spin pokestop)
      // buttonText = 'Spin Pokestop!';
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey.shade900,
      ),
      onPressed: () {
        if (_currentEncounter == EncounterType.CatchPokemon &&
            appState.pokeballCount > 0) {
          const double catchChance = 0.375;
          if (Random().nextDouble() > 1 - catchChance) {
            // If caught successfully
            appState.updateFound(appState.selectedWildIndex, 1);
            _showCaughtMessage(true); // Show "Caught!" message
          } else {
            print("Not caught");
            _showCaughtMessage(false);
          }
          appState.selectRandomPokemon(appState.location);
          appState.pokeballCount--;
        } else if (_currentEncounter == EncounterType.CatchPokemon &&
            appState.pokeballCount <= 0) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('No More Pokeballs!'),
                content: Text(
                    'You have no more pokeballs left.\nVisit a pokestop to get more!'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          appState.selectRandomPokemon(appState.location);
          setState(() {
            _currentEncounter = EncounterType.CatchPokemon;
          });
        }
      },
      child: Text(
        buttonText,
        style: TextStyle(color: Colors.red.shade500),
      ),
    );
  }

  // This will be the main page
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Center(
              child: Text(
                "Catch Them All!",
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              right: 8,
              child: Column(
                children: [
                  Image.asset(
                    'assets/pokeball.png',
                    width: 25,
                    height: 25,
                  ),
                  Text(
                    'Pokeballs: ${appState.pokeballCount}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        titleTextStyle: TextStyle(fontSize: 30),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5),
          AnimatedOpacity(
              opacity: _showCaughtText ? 1.0 : 0.0, // AnimatedOpacity widget
              duration: Duration(milliseconds: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  _caughtMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              )),
          if (appState.selectedPokemon != null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/sprites/${appState.selectedPokemon!.number}.gif',
                    height: 64, // Adjust height as needed
                    width: 64, // Adjust width as needed
                    fit: BoxFit.contain,
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
              child: _buildThrowPokeballButton(context),
            ),
          )
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

  Widget buildMapButton({
    required VoidCallback onPressed,
    required String buttonText,
    required double top,
    required double left,
    required Color primaryColor,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              backgroundColor: Colors.white,
            ),
            child: Icon(Icons.pin_drop),
          ),
          SizedBox(height: 3.0),
          Container(
            padding: EdgeInsets.symmetric(vertical: 1.0, horizontal: 5.0),
            decoration: BoxDecoration(
              color: Colors.white70,
              border: Border.all(color: primaryColor),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              buttonText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var primaryColor = appState.barColor;

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Center(
              child: Text(
                "Map",
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: 10,
              right: 16,
              child: Text(
                'Current Location: ${appState.location}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
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
            buildMapButton(
              onPressed: () {
                updateLocation(1);
                print("Richmond");
              },
              buttonText: 'Richmond Building',
              top: 190,
              left: 130,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(2);
                print("Catherine House");
              },
              buttonText: 'Catherine House',
              top: 60,
              left: 560,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(3);
                print("Rosalind Franklin");
              },
              buttonText: 'Rosalind Franklin',
              top: 360,
              left: 450,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(4);
                print("Library");
              },
              buttonText: 'Library',
              top: 630,
              left: 270,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(5);
                print("Guildhall");
              },
              buttonText: 'Guildhall',
              top: 240,
              left: 580,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(6);
                print("Eldon Building");
              },
              buttonText: 'Eldon Building',
              top: 490,
              left: 670,
              primaryColor: primaryColor,
            ),
            buildMapButton(
              onPressed: () {
                updateLocation(7);
                print("Bateson Hall");
              },
              buttonText: 'Bateson Hall',
              top: 350,
              left: 690,
              primaryColor: primaryColor,
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

    // Length of box when only looking at found pokemon (a.k.a found count)
    int foundPokemonCount = box.values.where((pokemon) => pokemon.found).length;

    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Center(
              child: Text(
                "Pokedex",
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: 10,
              right: 16,
              child: Text(
                'Found: $foundPokemonCount/151',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Positioned(
              left: 8,
              child: IconButton(
                icon: Icon(Icons.help),
                onPressed: () {
                  _showHelpDialog(context);
                },
              ),
            ),
          ],
        ),
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
                            pokemon?.name ?? "",
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pokedex Help'),
          content: Text(
            "This is the Pokedex page where you can view different Pokémon. "
            "You can tap on a Pokémon to view more details about it. "
            "The 'Found' count shows the number of Pokémon you have found "
            "out of the total 151 available Pokémon. "
            "Can't find someone? Different Pokémon appear in different locations! ",
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
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
                    pokemon?.name ?? "",
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
