import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'f-2048',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const Game2048(),
    );
  }
}

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  final int gridSize = 4; // Taille de la grille
  late List<List<int>> grid;
  int moveCount = 0; // Compteur des mouvements
  int goal = 2048; // Objectif de jeu
  bool randomStart = false; // Option grille aléatoire

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    setState(() {
      grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 0));
      if (randomStart) {
        _fillRandomGrid();
      } else {
        _addRandomTile();
        _addRandomTile();
      }
      moveCount = 0;
    });
  }

  // Remplir une grille aléatoire (avec puissances de 2 valides uniquement)
  void _fillRandomGrid() {
    final random = Random();
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        // Générer des puissances de 2 (2, 4, 8, 16, ...)
        grid[y][x] = random.nextBool() ? (2 << random.nextInt(5)) : 0;
      }
    }
  }

  // Ajoute une tuile aléatoire (2 ou 4)
  void _addRandomTile() {
    final emptyTiles = <Offset>[];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] == 0) emptyTiles.add(Offset(x.toDouble(), y.toDouble()));
      }
    }
    if (emptyTiles.isNotEmpty) {
      final randomIndex = Random().nextInt(emptyTiles.length);
      final position = emptyTiles[randomIndex];
      grid[position.dy.toInt()][position.dx.toInt()] = Random().nextBool() ? 2 : 4;
    }
  }

  // Déplacement vers le haut
  void _moveUp() {
    for (int x = 0; x < gridSize; x++) {
      final column = List.generate(gridSize, (y) => grid[y][x]);
      final newColumn = _mergeAndShiftRow(column);
      for (int y = 0; y < gridSize; y++) {
        grid[y][x] = newColumn[y];
      }
    }
  }

  // Déplacement vers le bas
  void _moveDown() {
    for (int x = 0; x < gridSize; x++) {
      final column = List.generate(gridSize, (y) => grid[y][x]);
      final newColumn = _mergeAndShiftRow(column.reversed.toList()).reversed.toList();
      for (int y = 0; y < gridSize; y++) {
        grid[y][x] = newColumn[y];
      }
    }
  }

  // Déplacement vers la gauche
  void _moveLeft() {
    for (int y = 0; y < gridSize; y++) {
      grid[y] = _mergeAndShiftRow(grid[y]);
    }
  }

  // Déplacement vers la droite
  void _moveRight() {
    for (int y = 0; y < gridSize; y++) {
      grid[y] = _mergeAndShiftRow(grid[y].reversed.toList()).reversed.toList();
    }
  }

  // Fusion et déplacement (garantie des puissances de 2 uniquement)
  List<int> _mergeAndShiftRow(List<int> row) {
    row = row.where((value) => value != 0).toList();
    for (int i = 0; i < row.length - 1; i++) {
      if (row[i] == row[i + 1]) {
        row[i] *= 2;
        row[i + 1] = 0;
      }
    }
    return row.where((value) => value != 0).toList() + List.filled(gridSize - row.length, 0);
  }

  // Vérifie si la partie est terminée
  bool _checkGameOver() {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x] == 0) return false;
        if (x < gridSize - 1 && grid[y][x] == grid[y][x + 1]) return false;
        if (y < gridSize - 1 && grid[y][x] == grid[y + 1][x]) return false;
      }
    }
    return true;
  }

  // Vérifie si l'objectif est atteint
  bool _checkVictory() {
    for (var row in grid) {
      if (row.contains(goal)) return true;
    }
    return false;
  }

  void _handleSwipe(SwipeDirection direction, Offset offset) {
    setState(() {
      bool moved = false;
      switch (direction) {
        case SwipeDirection.up:
          _moveUp();
          moved = true;
          break;
        case SwipeDirection.down:
          _moveDown();
          moved = true;
          break;
        case SwipeDirection.left:
          _moveLeft();
          moved = true;
          break;
        case SwipeDirection.right:
          _moveRight();
          moved = true;
          break;
        default:
          return;
      }

      if (moved) {
        if (_checkGameOver()) {
          _showEndDialog("Game Over!");
        } else {
          _addRandomTile();
          moveCount++;
          if (_checkVictory()) {
            _showEndDialog("You Win!");
          } else {
            // Affiche le message "Le jeu continue..." dans un SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Le jeu continue..."),
                duration: Duration(seconds: 1), // Durée du message
              ),
            );
          }
        }
      }
    });
  }


  // Affiche un dialogue de fin de partie
  void _showEndDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGrid();
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('f-2048'),
        centerTitle: true, // Centre le titre dans l'AppBar
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "f-2048",
                applicationVersion: "1.0",
                children: [const Text("Développé avec Flutter.")],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Centre horizontalement
              children: [
                DropdownButton<int>(
                  value: goal,
                  items: [256, 512, 1024, 2048].map((value) {
                    return DropdownMenuItem(value: value, child: Text("Objectif : $value"));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      goal = value!;
                      _initializeGrid();
                    });
                  },
                ),
                const SizedBox(height: 8), // Espace entre l'objectif et le nombre de coups
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange, // Fond orange
                    borderRadius: BorderRadius.circular(8), // Bords arrondis
                  ),
                  child: Text(
                    "Coups : $moveCount",
                    style: const TextStyle(
                      color: Colors.white, // Texte blanc
                      fontSize: 18, // Taille du texte
                      fontWeight: FontWeight.bold, // Mettre en gras
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SwipeDetector(
              onSwipe: _handleSwipe,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(gridSize, (y) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gridSize, (x) {
                      return Container(
                        margin: const EdgeInsets.all(5),
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: grid[y][x] == 0
                              ? Colors.grey[300]
                              : _getTileColor(grid[y][x]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          grid[y][x] != 0 ? grid[y][x].toString() : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          CheckboxListTile(
            title: const Text("Grille aléatoire"),
            value: randomStart,
            onChanged: (value) {
              setState(() {
                randomStart = value!;
              });
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 25.0),
        child: FloatingActionButton(
          onPressed: _initializeGrid,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  // Retourne la couleur d'une tuile selon sa valeur
  Color? _getTileColor(int value) {
    return {
      2: Colors.orange[200],
      4: Colors.orange[300],
      8: Colors.orange[400],
      16: Colors.orange[500],
      32: Colors.orange[600],
      64: Colors.orange[700],
      128: Colors.orange[800],
      256: Colors.orange[900],
      512: Colors.red[400],
      1024: Colors.red[500],
      2048: Colors.red[600],
    }[value] ?? Colors.grey[300];
  }
}
